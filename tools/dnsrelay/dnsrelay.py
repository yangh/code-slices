#!/usr/bin/env python
#
# Copyright 2010 pen9u1n
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

from google.appengine.api import urlfetch

from dns import DNS
from dns import CANT_RESOLVE
from StringIO import StringIO

#import base64
import httplib 
import logging

class WebRequestError(Exception):
    def __init__(self, msg = "Web request error"):
        self.msg = msg
    def __str__(self):
        return self.msg

class DNSWeb(DNS):
    def __init__(self):
        self.server = "DNSWeb"
        self.target = ""
        self.read_max = 1024

    def do_web_lookup(self, domain):
        data = ""

        try:
            httpconn = httplib.HTTPConnection(self.server, 80)
            target = self.target % domain
            logging.debug("Query: %s%s" % (self.server, target))

            httpconn.request('GET', target)
            response = httpconn.getresponse()
            data = response.read(self.read_max)
        except urlfetch.DownloadError:
            logging.error("Failed to query: %s%s" % (self.server, target))
            raise WebRequestError()

        return data

    def _parse_address(self, domain, data):
        return CANT_RESOLVE

    def lookup(self, domain):
        address = CANT_RESOLVE
        if (len(domain) > 0):
            data = self.do_web_lookup(domain)
            address = self._parse_address (domain, data)

        if (len(address) == 0 or address == domain):
            address = CANT_RESOLVE

        logging.debug("Resovled: %s, by %s" % (address, self.server))

        return address

class DNSWebLookupserverOcom(DNSWeb):
    def __init__(self):
        DNSWeb.__init__(self)
        self.server = "www.lookupserver.com"
        self.target = "/?forward_dns=%s&submit=Lookup"
        self.add_offset = 769 # char offset
    
    """
    Parse result in the html, start at offset 769
      Resovled:
      <tr><td align=right width="50%">IP address of g.cn:</td>
      <td width="50%">203.208.37.104</td></tr></td></tr></table>

      Can't be resolved:
      <tr><td align=right width="50%">IP address of g.cnx:</td>
      <td width="50%">g.cnx</td></tr></td></tr></table>

    If the domain contains special char like '-*', output in the
    first line remain as those chars filtered out.
    """
    def _parse_address(self, domain, data):
        if (len(data) == 0):
            return CANT_RESOLVE

        # Fix special char in domain, lookupserver filtered it in output
        special_chars = 0
        for ch in domain:
            if ch == '-':
                special_chars += 1

        start = data[self.add_offset + len(domain) - special_chars:]
        off = 0
        found = False
        address = ""
        while (off < len(start)):
            if (start[off] == '<'):
                found = True
                break
            else:
                off = off + 1
        if found:
            address = start[0:off]

        return address

class DNSWebBlokeOcom(DNSWeb):
    def __init__(self):
        DNSWeb.__init__(self)
        self.server = "www.bloke.com"
        self.target = "/cgi-bin/nslookup?%s"
        self.add_offset = 15  # line number
    
    """
    Output in line 15:

    Resovled:
      Address: 64.95.64.197

    Can't be resolved:
      ** server can't find www.blocke.comx: NXDOMAIN
    """
    def _parse_address(self, domain, data):
        if (len(data) == 0):
            return CANT_RESOLVE

        f = StringIO(data)
        lines = f.readlines()

        if (len(lines) < self.add_offset or
            len(lines[self.add_offset - 1]) == 0):
            return CANT_RESOLVE

        res = lines[self.add_offset - 1]
        if (res[0] == '*'):
            return CANT_RESOLVE

        parts = res.split()
        if (len(parts) < 2):
            return CANT_RESOLVE

        address = parts[1]

        return address

def main():
    print "Do some test here."

if __name__ == '__main__':
    main()
