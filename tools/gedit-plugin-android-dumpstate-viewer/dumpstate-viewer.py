#!/usr/bin/env python

from gettext import gettext as _

import re
import gtk
import gedit

# Menu item example, insert a new item in the Tools menu
ui_str = """<ui>
  <menubar name="MenuBar">
    <menu name="ToolsMenu" action="Tools">
      <placeholder name="ToolsOps_2">
        <menuitem name="DumpstateViewer" action="DumpstateViewer"/>
      </placeholder>
    </menu>
  </menubar>
</ui>
"""

class DumpstateViewerWindowHelper:
    def __init__(self, plugin, window):
        self._window = window
        self._plugin = plugin

        # Insert menu items
        #self._insert_menu()

        # Add side pane
        self._add_section_pane()
 
        self._window.connect("active-tab-changed", self.active_tab_changed, window)
        #self._window.connect("tab-added", self.active_tab_changed, window)

    def section_finder(self, filename):
        pat = re.compile (r'-----.*.[A-Z].*.------', re.M|re.I)
        #print "Parse file ", filename
	lines = None
        try:
            lines = open(filename).readlines()
	except:
            return {}

        idx = 1
        sections = {}
	last_sec = 0
        for line in lines:
            if pat.match(line) is not None:
                info = line.replace("------", "").strip().split("(")
                section = {}
                section["start"] = idx
                section["end"] = idx
                section["name"] = info[0]
	        if len(info) > 1:
                    section["desc"] = info[1].replace(")", "")
                else:
                    section["desc"] = info[0]
            
                sections[idx] = section
                if last_sec > 0:
                    sections[last_sec]["end"] = idx - 1
		last_sec = idx
            idx = idx + 1

        return sections

    def active_tab_changed(self, window, tab, data):
        doc = tab.get_document()
        txt = doc.get_uri_for_display()
        secs = self.section_finder(txt)
        for idx in sorted(secs.keys()):
             self.listStore.append([secs[idx]])
        self._sections = secs
	self._current_doc = doc
	self._current_view = tab.get_view()

    def deactivate(self):
        # Remove any installed menu items
        #self._remove_menu()

        self._window = None
        self._plugin = None
        self._action_group = None

    def _doc_loaded(self, view):
        # add section
        pass

    def _add_section(self, title, line):
        # add section
        pass

    def _section_selected(self, title, line):
        # goto section
        pass

    def _goto_line(self, line):
	if self._current_doc:
            #print "Goto line ", line 
            self._current_doc.goto_line(line)
	    self._current_view.scroll_to_cursor()

    def _goto_section_start(self, treeselection):
        (model, iter) = treeselection.get_selected()
	if iter is None:
            return

	sec = model.get_value(iter, 0)
	self._goto_line(sec["start"])

    def _goto_section_end(self, treeview, path, column):
        model = treeview.get_model()
        iter = model.get_iter(path)
	sec = model.get_value(iter, 0)
	self._goto_line(sec["end"])

    def _section_lineno(self, column, cell, model, iter):
        sec = model.get_value(iter, 0)
        cell.set_property('text', sec["start"])
        return

    def _section_name(self, column, cell, model, iter):
        sec = model.get_value(iter, 0)
        cell.set_property('text', sec["name"])
        return

    def _create_section_pane(self):
        # create a TreeStore with one string column to use as the model
        self.listStore = gtk.ListStore(object)

        # create the TreeView using treestore
        self.treeview = gtk.TreeView()

        # create the TreeViewColumn to display the data
        cell = gtk.CellRendererText()
        self.line_column = gtk.TreeViewColumn('Line', cell)
	self.line_column.set_cell_data_func(cell, self._section_lineno)
	#self.line_column.set_visible(False)

        cell = gtk.CellRendererText()
	#cell.set_property('xalign', 1.0)
        self.section_column = gtk.TreeViewColumn('Section', cell)
	self.section_column.set_cell_data_func(cell, self._section_name)

        # add tvcolumn to treeview
        self.treeview.append_column(self.line_column)
        self.treeview.append_column(self.section_column)
	self.treeview.set_model(self.listStore)
        self.treeview.connect('row-activated', self._goto_section_end)
	self.selection = self.treeview.get_selection()
	self.selection.connect('changed', self._goto_section_start)

        self.scrolled_window = gtk.ScrolledWindow(hadjustment=None, vadjustment=None)
	self.scrolled_window.set_policy(gtk.POLICY_AUTOMATIC, gtk.POLICY_ALWAYS)
	self.scrolled_window.add(self.treeview)
	self.scrolled_window.show_all()

        #return self.treeview
        return self.scrolled_window

    def _add_section_pane(self):
        icon = gtk.Image()
        icon.set_from_stock(gtk.STOCK_INDEX, gtk.ICON_SIZE_MENU)
        item = self._create_section_pane()
        panel = self._window.get_side_panel()
        panel.add_item(item, "Dumper Index", icon)
 
        self._section_pane = item

    def _insert_menu(self):
        # Get the GtkUIManager
        manager = self._window.get_ui_manager()

        # Create a new action group
        self._action_group = gtk.ActionGroup("DumpstateViewerPluginActions")
        self._action_group.add_actions([("DumpstateViewer", None, _("Clear document"),
                                         None, _("Clear the document"),
                                         self.on_clear_document_activate)])

        # Insert the action group
        manager.insert_action_group(self._action_group, -1)

        # Merge the UI
        self._ui_id = manager.add_ui_from_string(ui_str)

    def _remove_menu(self):
        # Get the GtkUIManager
        manager = self._window.get_ui_manager()

        # Remove the ui
        manager.remove_ui(self._ui_id)

        # Remove the action group
        manager.remove_action_group(self._action_group)

        # Make sure the manager updates
        manager.ensure_update()

    def update_ui(self):
        doc = self._window.get_active_document()
        #self._action_group.set_sensitive(doc != None)

    # Menu activate handlers
    def on_clear_document_activate(self, action):
        doc = self._window.get_active_document()
        if not doc:
            return

        doc.set_text('')

class DumpstateViewerPlugin(gedit.Plugin):
    def __init__(self):
        gedit.Plugin.__init__(self)
        self._instances = {}

    def activate(self, window):
        self._instances[window] = DumpstateViewerWindowHelper(self, window)

    def deactivate(self, window):
        self._instances[window].deactivate()
        del self._instances[window]

    def update_ui(self, window):
        self._instances[window].update_ui()


