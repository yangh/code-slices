/***************************************************************************
 *   Copyright (C) 2005 by yunfan                                          *
 *   yunfan_zg@163.com                                                     *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.             *
 ***************************************************************************/
 
 #ifndef EVAIPADDRESS_H
 #define EVAIPADDRESS_H
 
 #include <inttypes.h>
 #include <string>

 /*
 	this class is only for ipv4 addresses
	this class can be used as below:
	
	EvaIPAddress addr("255.255.255.255"); // or EvaIPAddress addr(0xffffffff) ;
	uint ip = addr.IP();
	std::string strIP = addr.toString();
 */
 class EvaIPAddress{
 public:
 	EvaIPAddress() {};
 	EvaIPAddress(const uint ip);
	EvaIPAddress(const std::string &strIP);
	EvaIPAddress(const EvaIPAddress &address);
	
	void setAddress(const uint ip);
	void setAddress(const std::string &strIP);
	const bool isValid() const;
	const uint IP() const;
	const std::string toString();
	EvaIPAddress &operator= (const EvaIPAddress &rhs);
private:
	bool isValidIP;
	uint mIP;
	uint getIntIP(const std::string &strIP);
};
 
#endif
