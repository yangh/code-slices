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

#import base64
import httplib 

DNSSERVER="8.8.8.8"
LOOKUPSERVER="www.lookupserver.com"
ADDRESSOFFSET=769
URL="/?forward_dns=%s&submit=Lookup"
CANT_RESOLVE="-"

class MainHandler(webapp.RequestHandler):
    def do_dns_lookup(self, domain):
        httpconn = httplib.HTTPConnection(LOOKUPSERVER, 80)
        target = URL % domain
        httpconn.request('GET', target)
        response = httpconn.getresponse()
        data = response.read(1024)

        return data

    # FIXME: Find a nother way to parse result
    def _parse_address(self, domain, data):

        # lookupserver.com filtered '-' char in output.
        special_chars = 0
        for ch in domain:
            if ch == '-':
                special_chars += 1

        start = data[ADDRESSOFFSET + len(domain) - special_chars:]
        off = 0
        found = False
        address = ""

        max_ip_len = 16

        while (off < len(start) and off < max_ip_len):
            if (start[off] == '<'):
                found = True
                break
            else:
                off = off + 1
        if found:
            address = start[0:off]

        return address

    def dns_lookup(self, domain):
        if (len(domain) == 0):
            return CANT_RESOLVE
        
        data = self.do_dns_lookup(domain)
        address = self._parse_address (domain, data)

        if (len(address) == 0 or address == domain):
            #print "Cann't resolve this domain, equal to request"
            address = CANT_RESOLVE

        return address

    def unshake(self, input_str):
        output_str = ""

        i = 0
        n = 0
        while (n < len(input_str) / 2):
            output_str += input_str[i + 1]
            output_str += input_str[i]
            i += 2
            n += 1

        if (i < len(input_str)):
            output_str += input_str[-1]

        return output_str

    def get(self):
        domain = self.unshake(self.request.query_string)
        ret = self.dns_lookup(domain)
        self.response.out.write(ret)

def main():
    application = webapp.WSGIApplication([('/', MainHandler)],
                                         debug=True)
    util.run_wsgi_app(application)


if __name__ == '__main__':
    main()
