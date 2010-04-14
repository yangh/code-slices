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
#ifndef EVAIPSEEKER_H
#define EVAIPSEEKER_H

#include <string>
#include <fstream>


class EvaIPSeeker
{
public:
  EvaIPSeeker();
  EvaIPSeeker(std::string absPath);
  ~EvaIPSeeker();

  const std::string getIPLocation(const std::string ip);
  const std::string getIPLocation(const unsigned int ip);
  const bool isQQWryExisted();
  
private:
  unsigned int searchIP(const unsigned int ip);
  unsigned int readIP(unsigned int offset);
  unsigned int getMiddleOffset(const unsigned int begin, const unsigned int end);
  int compareIP(const unsigned int ip1, const unsigned int ip2);
  std::string getIPRecord(const unsigned int offset);
  std::string readString(const unsigned int offset);
  std::string readArea(const unsigned int offset);
  bool getIndexOffset(std::fstream& inputfile);
 
private:
  std::fstream ipFile;     //file i/o stream 
  std::string fileName;    //the data file path
  int firstIndexOffset;    //the first index offset of the index area
  int lastIndexOffset;     //the last index offset of the index area
  char byte4[4];           //tmp char array
  char byte3[3];           //tmp char array
};


#endif
