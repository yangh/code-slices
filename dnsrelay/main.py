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

from dnsrelay import DNS
from dnsrelay import DNSWeb
from dnsrelay import CANT_RESOLVE
from dnshosts import DNSHosts
from dnshosts import DNSHostsManager

#import base64
import httplib 

class MainHandler(webapp.RequestHandler):
    def get(self):
        domain = DNS.unshake(self.request.query_string)
        if (len(domain) == 0):
            self.response.out.write(CANT_RESOLVE)
            return

        dns = DNSHosts()
        ret = dns.lookup(domain)
        if (ret != CANT_RESOLVE):
            self.response.out.write(ret)
            return

        dns = DNSWeb()
        ret = dns.lookup(domain)
        self.response.out.write(ret)

class DNSHostsManagerHandler(webapp.RequestHandler):
    def get(self):
        dhm = DNSHostsManager()
        dhm.load_hosts("cmwrap.googlecode.com", "/svn/wiki/hosts.wiki")
        self.response.out.write("Hosts count = %d" % dhm.count())

def main():
    application = webapp.WSGIApplication([('/', MainHandler),
                                          ('/dhm/', DNSHostsManagerHandler)],
                                         debug=True)
    util.run_wsgi_app(application)


if __name__ == '__main__':
    main()
