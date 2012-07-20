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

from google.appengine.ext import db
import re

CANT_RESOLVE = "-"

class Host(db.Model):
    ip = db.StringProperty()
    domain = db.StringProperty()

class DNS(object):
    def __init__(self):
        pass
    
    def lookup(self, domain):
        pass
    
    @staticmethod
    def unshake(input_str):
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

    """
    The following code is from:
        http://stackoverflow.com/questions/2532053/validate-hostname-string-in-python
    """
    @staticmethod
    def isValidHostname(hostname):
        if len(hostname) > 255:     # Max domain name length
            return False

        if hostname.endswith("."):  # A single trailing dot is legal, strip it
            hostname = hostname[:-1]

        if hostname.find(".") == -1: # At least one section, as a domain name in the internet. - for dnsrelay
            return False

        disallowed = re.compile("[^A-Z\d-]", re.IGNORECASE)

        return all(                             # Split by labels and verify individually
            (label and len(label) <= 63         # length is within proper range
             and not label.startswith("-")      # no bordering hyphens
             and not label.endswith("-")
             and not disallowed.search(label))  # contains only legal characters
            for label in hostname.split("."))


def main():
    print "Do some test here."

if __name__ == '__main__':
    main()
