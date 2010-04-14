/***************************************************************************
 *   Copyright (C) 2005 by casper                                          *
 *   tlmcasper@163.com                                                     *
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
#include <iostream>
#include <string>
#include <fstream>

#include "evaipseeker.h"
#include "evaipaddress.h"

#define STRING_LEN        80
#define IP_RECORD_LENGTH  7
#define REDIRECT_MODE_1   0x01
#define REDIRECT_MODE_2   0x02
#define DATAFILENAME      "QQWry.dat"

#define READINT3(X) (( X[0] & 0xFF )|(( X[1] & 0xFF)<< 8 )|(( X[2] & 0xFF )<< 16 ))
#define READINT4(X) (( X[0] & 0xFF )|(( X[1] & 0xFF)<< 8 )|(( X[2] & 0xFF )<< 16 )|(( X[3] & 0xFF ) << 24 ))

using namespace std;

//get the path of IP data file which is in the working directory,store in @fileName
//param:null
//return:null
EvaIPSeeker::EvaIPSeeker()
{
  fileName = DATAFILENAME;
}

//get the absolute path of IP data file,store it in @fileName;
//param: string absPath
//return: null
EvaIPSeeker::EvaIPSeeker(string absPath)
{
  fileName = absPath + "/" + DATAFILENAME;
}

//check the status of IP data file,close it if it opened.
//param: null
//return: null
EvaIPSeeker::~EvaIPSeeker()
{
   if(ipFile.is_open())
      ipFile.close();
}

//check if QQWry.dat exists
//param: null
//return: true or false
const bool EvaIPSeeker::isQQWryExisted()
{
  ipFile.open(fileName.c_str(), ios::in);
  if(!ipFile)
    return false;
  else
  {
    ipFile.close();
    return true;
  }
}

//search ip in the index area of IP data file,return the offset of IP record if found.
//param: unsigned int ip
//return: unsigned int offset
unsigned int EvaIPSeeker::searchIP(const unsigned int ip)
{
  unsigned int startIP;
  unsigned int endIP;
  unsigned int midIP,mOffset;
  int r;
  unsigned int i,j;

  startIP = readIP(firstIndexOffset);
  endIP = readIP(lastIndexOffset);
  r = compareIP(ip,startIP);
  if(r == 0)
      return firstIndexOffset;
  else if(r < 0) 
      return 0;
  for(i = firstIndexOffset, j = lastIndexOffset; i < j;)
  {
    mOffset = getMiddleOffset(i, j);
    midIP = readIP(mOffset);
    r = compareIP(ip, midIP);
    if(r > 0)
      i = mOffset;
    else if(r < 0)
    {
      if(mOffset == j)
      {
        j -= IP_RECORD_LENGTH;
        mOffset = j;
      }
      else
        j = mOffset;
    }
    else
    {
      if(!ipFile.is_open())
          ipFile.open(fileName.c_str(), ios::in|ios::binary);
      ipFile.seekg(mOffset+4, ios::beg);
      ipFile.read(byte3, 3);
      ipFile.close();
      return READINT3(byte3);
    }
  }
  if(!ipFile.is_open())
      ipFile.open(fileName.c_str(), ios::in|ios::binary);
  ipFile.seekg(mOffset+4, ios::beg);
  ipFile.read(byte3, 3);
  midIP = readIP(READINT3(byte3));
  r = compareIP(ip, midIP);
  if(r <= 0) return READINT3(byte3);
  else return 0;
}

//read 4 bytes start from the offset,and change them to an IP address.
//param: unsigned int offset
//return: unsigned int IP
unsigned int EvaIPSeeker::readIP(unsigned int offset)
{
  unsigned int tmpIP;
  if(!ipFile.is_open())
      ipFile.open(fileName.c_str(), ios::in|ios::binary);
  ipFile.seekg(offset, ios::beg);
  ipFile.read(byte4,4);
  tmpIP = READINT4(byte4);
  ipFile.close();
  return tmpIP;
}

//compare two IP
//param: unsigned int ip1, unsigned int ip2
//return: int result
int EvaIPSeeker::compareIP(const unsigned int ip1, const unsigned int ip2)
{
  if( ip1 > ip2 ) return 1;
  else if ( ip1 < ip2 ) return -1;
  else  return 0;
}

//get the middle offset of two offsets.
//param: unsigned int begin, unsigned int end
//return: unsigned int theMiddleOffset
unsigned int EvaIPSeeker::getMiddleOffset(const unsigned int begin, const unsigned int end)
{
  int records = (end - begin) / IP_RECORD_LENGTH;
  records >>= 1;
  if(records == 0) records = 1;
  return begin + records * IP_RECORD_LENGTH;
}

//read a string start from the offset until meet a char '\0'
//param: unsigned int offset
//return: string str
string EvaIPSeeker::readString(const unsigned int offset)
{
  static char tmpstr[STRING_LEN];
  string str;
  ipFile.seekg(offset, ios::beg);
  ipFile.getline(tmpstr,STRING_LEN,'\0');
  str = tmpstr;
  return str;
}

//get one IP record (country and area) of the offset
//param: unsigned int offset
//return: string location
string EvaIPSeeker::getIPRecord(const unsigned int offset)
{
  char flag;
  string country;
  string area;
  string location;
  unsigned int countryOffset;

  if(!ipFile.is_open())
      ipFile.open(fileName.c_str(), ios::in|ios::binary);
  ipFile.seekg(offset+4, ios::beg);//ignore the ip data
  ipFile.get(flag);
  if(flag == REDIRECT_MODE_1)
  {
    ipFile.read(byte3, 3);
    countryOffset = READINT3(byte3); //get the offset of country data
    ipFile.seekg(countryOffset);
    ipFile.get(flag); // check the flag again,maybe it's an other redirectroy
    if(flag == REDIRECT_MODE_2)
    {
      ipFile.read(byte3, 3);
      country = readString(READINT3(byte3));
      ipFile.seekg(countryOffset+4);//if mode2,we need pass 4 bytes to reach the area data;
    }
    else
    {
      country = readString(countryOffset);
    }
    area = readArea(ipFile.tellg());
  }
  else if(flag == REDIRECT_MODE_2)
  {
    ipFile.read(byte3, 3);
    country = readString(READINT3(byte3));
    area = readArea(offset+8);
  }
  else
  {
    ipFile.putback(flag);//make the inside pointer back 1 character
    country = readString(ipFile.tellg());
    area = readArea(ipFile.tellg());
  }
  location = country + area;
  ipFile.close();
  return location;
}

//read the Area data start from the offset.
//param: unsigned int offset
//return: string areaData
string EvaIPSeeker::readArea(const unsigned int offset)
{
  char flag;
  unsigned int areaOffset;
  
  ipFile.seekg(offset, ios::beg);
  ipFile.get(flag);
  if(flag == REDIRECT_MODE_1 || flag == REDIRECT_MODE_2)
  {
    ipFile.read(byte3, 3);
    areaOffset = READINT3(byte3);
    if(areaOffset != 0)
      return readString(areaOffset);
    else
      return "Unknow Area";//if the areaoffset is zero,it's show there's no data for the area
  }
  else
    return readString(offset);

}

//get the Index arrange of the Index area from infile
//param: fstream& infile
//return: true or false
bool EvaIPSeeker::getIndexOffset(fstream& infile)
{
  infile.seekg(ios::beg);
  infile.read(byte4, 4);
  firstIndexOffset = READINT4(byte4);
  infile.read(byte4, 4);
  lastIndexOffset = READINT4(byte4);
  if(( firstIndexOffset == -1 )||( lastIndexOffset == -1 ))
  {
    return false;
  }
  return true;
}

//main function, get the location of an IP address,if IP is not valid or the Data file missed then return IP address. 
//param: unsigned int ip
//return: string location or string ip
const string EvaIPSeeker::getIPLocation(const unsigned int ip)
{
  EvaIPAddress addr(ip);
  if(!isQQWryExisted())
    return addr.toString();
  ipFile.open(fileName.c_str(), ios::in|ios::binary);
  if(!ipFile)
    return addr.toString();
  else
  {
    if(!getIndexOffset(ipFile))
    {
      ipFile.close();
      return addr.toString();
    }
    return getIPRecord(searchIP(addr.IP()));
  }
}

//main function, get the location of an IP address,if IP is not valid or the Data file missed then return IP address. 
//param: string ip
//return: string location or string ip
const string EvaIPSeeker::getIPLocation(const string ip)
{
  EvaIPAddress addr(ip);
  if(!addr.isValid())
    return addr.toString();
  if(!isQQWryExisted())
    return addr.toString();
  ipFile.open(fileName.c_str(), ios::in|ios::binary);
  if(!ipFile)
    return addr.toString();
  else
  {
    if(!getIndexOffset(ipFile))
    {
      ipFile.close();
      return addr.toString();
    }
    return getIPRecord(searchIP(addr.IP()));
  }
}

