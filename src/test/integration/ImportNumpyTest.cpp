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

//#include <nupic/engine/Network.hpp>
#include <nupic/engine/NuPIC.hpp>
#include <nupic/regions/PyRegion.hpp>

//#include <nupic/engine/Region.hpp>

//#include <nupic/engine/RegionImplFactory.hpp>



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


  /* This passed on Windows, too
  nupic::PyRegion::NTA_initPython();

  // Try one more time to see if import_array will fail
  nupic::PyRegion::NTA_initPython();

  return 0;
  */


  /* This is sufficient to reproduce on Windows (from PyRegionTest.cpp):
     "ImportError: numpy.core.multiarray failed to import":

  //std::cerr << "ZZZ calling NuPIC::init..." << std::endl;
  //nupic::NuPIC::init();
  //std::cerr << "ZZZ returned from NuPIC::init" << std::endl;

  //std::cerr << "ZZZ calling Network::registerPyRegion..." << std::endl;
  //nupic::Network::registerPyRegion("nupic.bindings.regions.TestNode", "TestNode");
  //std::cerr << "ZZZ returned from Network::registerPyRegion" << std::endl;

  nupic::Network n;

  std::cerr << "ZZZ calling n.addRegion..." << std::endl;
  nupic::Region* level2 = n.addRegion("level2", "py.TestNode", "{int32Param: 444}");
  std::cerr << "ZZZ returned from n.addRegion" << std::endl;
  */


  /* This one succeeded on _import_array, but failed later (probably because
     region wasn't registered)
     ERR:  Matching Python module for TestNode not found.

  // From Region:Region(name, nodeType, nodeParams, *network)
  nupic::RegionImplFactory & factory = nupic::RegionImplFactory::getInstance();

  std::cerr << "ZZZ calling factory.getSpec..." << std::endl;
  factory.getSpec("py.TestNode");
  std::cerr << "ZZZ returned from factory.getSpec" << std::endl;
  */


  /* This one succeeded all the way.
  std::cerr << "ZZZ calling Network::registerPyRegion..." << std::endl;
  nupic::Network::registerPyRegion("nupic.bindings.regions.TestNode", "TestNode");
  std::cerr << "ZZZ returned from Network::registerPyRegion" << std::endl;

  // From Region:Region(name, nodeType, nodeParams, *network)
  std::cerr << "ZZZ calling RegionImplFactory::getInstance..." << std::endl;
  nupic::RegionImplFactory & factory = nupic::RegionImplFactory::getInstance();
  std::cerr << "ZZZ returned from RegionImplFactory::getInstance" << std::endl;

  std::cerr << "ZZZ calling factory.getSpec..." << std::endl;
  factory.getSpec("py.TestNode");
  std::cerr << "ZZZ returned from factory.getSpec" << std::endl;

  // These was the code flow:
  //ZZZ calling Network::registerPyRegion...
  //ZZZ returned from Network::registerPyRegion
  //ZZZ calling RegionImplFactory::getInstance...
  //ZZZ returned from RegionImplFactory::getInstance
  //ZZZ calling factory.getSpec...
  //ZZZ calling boost::shared_ptr<DynamicPythonLibrary>...
  //ZZZ calling initPython_...
  //ZZZ Calling Py_Initialize...
  //ZZZ Returned from Py_Initialize...
  //ZZZ calling _import_array...
  //ZZZ returned from _import_array
  //ZZZ returned from initPython_
  //ZZZ returned from boost::shared_ptr<DynamicPythonLibrary>
  //ZZZ calling pyLib->createSpec...
  //ZZZ returned from pyLib->createSpec
  //ZZZ returned from factory.getSpec
  */


  /* Totally successful, similarly to direct factory.getSpec call above
  std::cerr << "ZZZ calling Network::registerPyRegion..." << std::endl;
  nupic::Network::registerPyRegion("nupic.bindings.regions.TestNode", "TestNode");
  std::cerr << "ZZZ returned from Network::registerPyRegion" << std::endl;

  // From Network::addRegion
  auto r = new nupic::Region("level2", "py.TestNode", "{int32Param: 444}");
  r = r;
  */

  /* Fails as before, and there was no unexpected call to Py_Finalize.
  // Back to n.addRegion, but with Py_Finalize instrumented in PyRegion.cpp
  nupic::Network n;

  std::cerr << "ZZZ calling n.addRegion..." << std::endl;
  nupic::Region* level2 = n.addRegion("level2", "py.TestNode", "{int32Param: 444}");
  std::cerr << "ZZZ returned from n.addRegion" << std::endl;
  */


  nupic::NuPIC::init();
  nupic::PyRegion::NTA_initPython();


  return 0;
}
