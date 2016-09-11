/* ---------------------------------------------------------------------
 * Numenta Platform for Intelligent Computing (NuPIC)
 * Copyright (C) 2016, Numenta, Inc.  Unless you have an agreement
 * with Numenta, Inc., for a separate license for this software code, the
 * following terms and conditions apply:
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero Public License version 3 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU Affero Public License for more details.
 *
 * You should have received a copy of the GNU Affero Public License
 * along with this program.  If not, see http://www.gnu.org/licenses.
 *
 * http://numenta.org/licenses/
 * ---------------------------------------------------------------------
 */

/*
 This test app simply initializes python and imports numpy.
*/


//#include <assert.h>

#include <iostream>

//#define NPY_NO_DEPRECATED_API NPY_1_7_API_VERSION
//#include <Python.h>
//#include <numpy/arrayobject.h>

#include <nupic/regions/PyRegion.hpp>


int main(int argc, char*argv[])
{
  /* This passes on Windows, so we'll try via PyRegion next
  if (!Py_IsInitialized())
  {
    std::cerr << "ZZZ Calling Py_Initialize..." << std::endl;
    Py_Initialize();
    std::cerr << "ZZZ Returned from Py_Initialize..." << std::endl;
    assert(Py_IsInitialized());
  }

  std::cerr << "ZZZ Calling import_array1..." << std::endl;
  // This macro will execute `return -1;` on failure and nothing on success.
  import_array1(-1);
  std::cerr << "ZZZ Returned from import_array1" << std::endl;

  return 0;
  */

  nupic::PyRegion::NTA_initPython();

  // Try one more time to see if import_array will fail
  nupic::PyRegion::NTA_initPython();

  return 0;
}
