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
from google.appengine.ext import webapp
from google.appengine.ext.webapp import util

from dns import DNS
from dns import CANT_RESOLVE
from dnsrelay import DNSWeb
from dnshosts import DNSHosts
from dnshosts import DNSHostsManager

#import base64
import httplib 
import logging

class MainHandler(webapp.RequestHandler):
    def get(self):
        domain = self.request.get("d")
        use_hosts = self.request.get("uh", default_value="0")

        # Compatible with dnsrelay 1.0, all query string as domain
        if (domain == ""):
            domain = self.request.query_string

        if len(domain) == 0:
            self.response.out.write(CANT_RESOLVE)
            return

        domain = DNS.unshake(domain)

        if not DNS.isValidHostname(domain):
            logging.debug("Invalid domain name: %s" % domain)
            self.response.out.write(CANT_RESOLVE)
            return

        # Query from hosts datastore
        if (use_hosts == "1"):
            dns = DNSHosts()
            ret = dns.lookup(domain)
            if (ret != CANT_RESOLVE):
                self.response.out.write(ret)
                #print "DNS from Hosts"
                return

        # Query from web
        dns = DNSWeb()
        ret = dns.lookup(domain)
        self.response.out.write(ret)

class DNSHostsManagerHandler(webapp.RequestHandler):
    def get(self):
        op = self.request.get("op", default_value="sum")
        dhm = DNSHostsManager()

        if (op == "sum"):
            self.response.out.write("Hosts count = %d." % dhm.count())
            return

        if (op == "listhost"):
            hosts = dhm.all()
            for h in hosts:
                self.response.out.write("%s, %s\n" % (h.ip, h.domain))
            return

        if (op == "delall"):
            dhm.del_all()
            self.response.out.write("Hosts count = %d." % dhm.count())
            return

        if (op == "load"):
            dhm.load_hosts("cmwrap.googlecode.com", "/svn/wiki/hosts.wiki")
            self.response.out.write("Loaded %d hosts." % dhm.count())

        if (op == "find"):
            q = self.request.get("q")
            hosts = dhm.find(q)
            for h in hosts:
                self.response.out.write("%s, %s\n" % (h.ip, h.domain))

def main():
    application = webapp.WSGIApplication([('/', MainHandler),
                                          ('/dhm/', DNSHostsManagerHandler)],
                                         debug=True)
    util.run_wsgi_app(application)


if __name__ == '__main__':
    main()
