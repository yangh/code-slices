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
  
#include "evaipaddress.h"
#include <stdlib.h>

EvaIPAddress::EvaIPAddress(const uint ip)
	:isValidIP(false)
{
	mIP = ip;
	isValidIP = true;
}

EvaIPAddress::EvaIPAddress(const std::string &strIP)
	:isValidIP(false)
{
	mIP = getIntIP(strIP);
	if(mIP)
		isValidIP = true;
}

EvaIPAddress::EvaIPAddress(const EvaIPAddress &address)
	:isValidIP(false)
{
	mIP = address.IP();
	isValidIP = address.isValid();
}

void EvaIPAddress::setAddress(const uint ip)
{
	mIP = ip;
}

void EvaIPAddress::setAddress(const std::string &strIP)
{
	mIP = getIntIP(strIP);
}

const bool EvaIPAddress::isValid() const
{
	return isValidIP;
}

const uint EvaIPAddress::IP() const
{
	return mIP;
}

const std::string EvaIPAddress::toString()
{
	char strIP[16];
	memset(strIP, 0, 16);
	sprintf(strIP, "%d.%d.%d.%d", (mIP&0xFF000000)>>24, (mIP&0x00FF0000)>>16, (mIP&0x0000FF00)>>8, (mIP&0x000000FF));
	return std::string(strIP);
}

EvaIPAddress &EvaIPAddress::operator= (const EvaIPAddress &rhs)
{
	mIP = rhs.IP();
	isValidIP = rhs.isValid();
	return *this;
}

uint EvaIPAddress::getIntIP(const std::string &strIP)
{
	int num = 0;
	for(uint i=0; i< strIP.length(); i++)
		if(strIP[i] == '.') num++;
	// check if it consists of 4 parts
	if(num != 3){
		isValidIP = false;
		return 0;
	}
	
	// get all 4 parts in 
	unsigned char parts[4];
	int start = 0, end = 0;
	for(int i=0; i<4; i++){
		for(uint j= start; j<strIP.length(); j++){
			if(strIP[j] == '.'){
				end = j;
				break;
			}
			if(strIP[j] < '0' || strIP[j] > '9'){
				isValidIP = false;
				return 0;
			}
		}
		//printf("3 strIP:%s\n",strIP.c_str());
		std::string tmp = strIP.substr(start, end - start);
		int tmpInt = atoi(tmp.c_str());
		
		if(tmpInt< 0 || tmpInt > 255){
			isValidIP = false;
			return 0;
		}
		parts[i] = (unsigned char)tmpInt;
		start = end + 1;
	}
	// put all 4 parts into one uint
	return ((uint)parts[0])<<24 | ((uint)parts[1])<<16 | ((uint)parts[2])<<8 | parts[3];
}

