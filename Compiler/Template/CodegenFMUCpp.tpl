// This file defines templates for transforming Modelica/MetaModelica code to FMU
// code. They are used in the code generator phase of the compiler to write
// target code.
//
// There are one root template intended to be called from the code generator:
// translateModel. These template do not return any
// result but instead write the result to files. All other templates return
// text and are used by the root templates (most of them indirectly).
//
// To future maintainers of this file:
//
// - A line like this
//     # var = "" /*BUFD*/
//   declares a text buffer that you can later append text to. It can also be
//   passed to other templates that in turn can append text to it. In the new
//   version of Susan it should be written like this instead:
//     let &var = buffer ""
//
// - A line like this
//     ..., Text var /*BUFP*/, ...
//   declares that a template takes a text buffer as input parameter. In the
//   new version of Susan it should be written like this instead:
//     ..., Text &var, ...
//
// - A line like this:
//     ..., var /*BUFC*/, ...
//   passes a text buffer to a template. In the new version of Susan it should
//   be written like this instead:
//     ..., &var, ...
//
// - Style guidelines:
//
//   - Try (hard) to limit each row to 80 characters
//
//   - Code for a template should be indented with 2 spaces
//
//     - Exception to this rule is if you have only a single case, then that
//       single case can be written using no indentation
//
//       This single case can be seen as a clarification of the input to the
//       template
//
//   - Code after a case should be indented with 2 spaces if not written on the
//     same line

package CodegenFMUCpp



import interface SimCodeTV;
import interface SimCodeBackendTV;
import CodegenUtil.*;
import CodegenCpp.*; //unqualified import, no need the CodegenC is optional when calling a template; or mandatory when the same named template exists in this package (name hiding)
import CodegenCppCommon.*;
import CodegenFMU.*;
import CodegenCppInit;
import CodegenFMUCommon;
import CodegenFMU2;

template translateModel(SimCode simCode, String FMUVersion, String FMUType)
 "Generates C++ code and Makefile for compiling an FMU of a Modelica model.
  Calls CodegenCpp.translateModel for the actual model code."
::=
match simCode
case SIMCODE(modelInfo=modelInfo as MODELINFO(__)) then
  let guid = getUUIDStr()
  let target  = simulationCodeTarget()
  let stateDerVectorName = "__zDot"
  let &extraFuncs = buffer "" /*BUFD*/
  let &extraFuncsDecl = buffer "" /*BUFD*/
  let &complexStartExpressions = buffer ""

  let numRealVars = numRealvars(modelInfo)
  let numIntVars = numIntvars(modelInfo)
  let numBoolVars = numBoolvars(modelInfo)
  let numStringVars = numStringvars(modelInfo)

  let cpp = CodegenCpp.translateModel(simCode)
  let()= textFile(fmuWriteOutputHeaderFile(simCode , &extraFuncs , &extraFuncsDecl, ""),'OMCpp<%fileNamePrefix%>WriteOutput.h')
  let()= textFile(fmuModelHeaderFile(simCode, extraFuncs, extraFuncsDecl, "",guid, FMUVersion), 'OMCpp<%fileNamePrefix%>FMU.h')
  let()= textFile(fmuModelCppFile(simCode, extraFuncs, extraFuncsDecl, "",guid, FMUVersion), 'OMCpp<%fileNamePrefix%>FMU.cpp')
  let()= textFile((if isFMIVersion10(FMUVersion) then CodegenCppInit.modelInitXMLFile(simCode, numRealVars, numIntVars, numBoolVars, numStringVars, FMUVersion, FMUType, guid, true, "cpp-runtime", complexStartExpressions, stateDerVectorName) else
                   CodegenFMU.fmuModelDescriptionFile(simCode, guid, FMUVersion, FMUType)), 'modelDescription.xml')
  let()= textFile(fmudeffile(simCode, FMUVersion), '<%fileNamePrefix%>.def')
  let()= textFile(fmuMakefile(target,simCode, extraFuncs, extraFuncsDecl, "", FMUVersion, "", "", "", ""), '<%fileNamePrefix%>_FMU.makefile')
  let()= textFile(fmuCalcHelperMainfile(simCode), 'OMCpp<%fileNamePrefix%>CalcHelperMain.cpp')
 ""
   // Return empty result since result written to files directly
end translateModel;

template fmuCalcHelperMainfile(SimCode simCode)
::=
  match simCode
    case SIMCODE(modelInfo = MODELINFO(__)) then
    <<
    /*****************************************************************************
    *
    * Helper file that includes all generated calculation files, except the alg loops.
    * This file is generated by the OpenModelica Compiler and produced to speed-up the compile time.
    *
    *****************************************************************************/
    #include <Core/ModelicaDefine.h>
    #include <Core/Modelica.h>
    #include <Core/System/FactoryExport.h>
    #include <Core/DataExchange/SimData.h>
    #include <Core/System/SimVars.h>
    #include <Core/System/DiscreteEvents.h>
    #include <Core/System/EventHandling.h>
    #include <Core/Utils/extension/logger.hpp>

    #include "OMCpp<%fileNamePrefix%>Types.h"
    #include "OMCpp<%fileNamePrefix%>.h"
    #include "OMCpp<%fileNamePrefix%>Functions.h"
    #include "OMCpp<%fileNamePrefix%>Jacobian.h"
    #include "OMCpp<%fileNamePrefix%>Mixed.h"
    #include "OMCpp<%fileNamePrefix%>StateSelection.h"
    #include "OMCpp<%fileNamePrefix%>WriteOutput.h"
    #include "OMCpp<%fileNamePrefix%>Initialize.h"
    #include "OMCpp<%fileNamePrefix%>FMU.h"

    #include "OMCpp<%fileNamePrefix%>AlgLoopMain.cpp"
    #include "OMCpp<%fileNamePrefix%>Mixed.cpp"
    #include "OMCpp<%fileNamePrefix%>Functions.cpp"
    <%if(boolOr(Flags.isSet(Flags.HARDCODED_START_VALUES), Flags.isSet(Flags.GEN_DEBUG_SYMBOLS))) then
    <<
    #include "OMCpp<%fileNamePrefix%>InitializeParameter.cpp"
    #include "OMCpp<%fileNamePrefix%>InitializeAlgVars.cpp"
    #include "OMCpp<%fileNamePrefix%>InitializeAliasVars.cpp"
    >>
    %>
    #include "OMCpp<%fileNamePrefix%>InitializeExtVars.cpp"
    #include "OMCpp<%fileNamePrefix%>Initialize.cpp"
    #include "OMCpp<%fileNamePrefix%>Jacobian.cpp"
    #include "OMCpp<%fileNamePrefix%>StateSelection.cpp"
    #include "OMCpp<%fileNamePrefix%>.cpp"
    #include "OMCpp<%fileNamePrefix%>FMU.cpp"
    >>
end fmuCalcHelperMainfile;

template fmuWriteOutputHeaderFile(SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace)
 "Overrides code for writing simulation file. FMU does not write an output file"
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(__),simulationSettingsOpt = SOME(settings as SIMULATION_SETTINGS(__))) then
  <<
  #pragma once

  // Dummy code for FMU that writes no output file
  class <%lastIdentOfPath(modelInfo.name)%>WriteOutput  : public IWriteOutput,public <%lastIdentOfPath(modelInfo.name)%>StateSelection
  {
   public:
    <%lastIdentOfPath(modelInfo.name)%>WriteOutput(IGlobalSettings* globalSettings, shared_ptr<ISimObjects> simObjects): <%lastIdentOfPath(modelInfo.name)%>StateSelection(globalSettings, simObjects) {}
    virtual ~<%lastIdentOfPath(modelInfo.name)%>WriteOutput() {}

    virtual void writeOutput(const IWriteOutput::OUTPUT command = IWriteOutput::UNDEF_OUTPUT) {}
    virtual IHistory* getHistory() {return NULL;}

   protected:
    void initialize() {}
  };
  >>
end fmuWriteOutputHeaderFile;

template fmuModelHeaderFile(SimCode simCode,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, String guid, String FMUVersion)
 "Generates declaration for FMU target."
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(__)) then
  let modelShortName = lastIdentOfPath(modelInfo.name)
  //let modelIdentifier = System.stringReplace(dotPath(modelInfo.name), ".", "_")
  <<
  // declaration for Cpp FMU target

  class <%modelShortName%>FMU: public <%modelShortName%>Initialize {
   public:
    // constructor
    <%modelShortName%>FMU(IGlobalSettings* globalSettings, shared_ptr<ISimObjects> simObjects);

    // initialization
    virtual void initialize();

    // getters for given value references
    virtual void getReal(const unsigned int vr[], int nvr, double value[]);
    virtual void getInteger(const unsigned int vr[], int nvr, int value[]);
    virtual void getBoolean(const unsigned int vr[], int nvr, int value[]);
    virtual void getString(const unsigned int vr[], int nvr, string value[]);

    // setters for given value references
    virtual void setReal(const unsigned int vr[], int nvr, const double value[]);
    virtual void setInteger(const unsigned int vr[], int nvr, const int value[]);
    virtual void setBoolean(const unsigned int vr[], int nvr, const int value[]);
    virtual void setString(const unsigned int vr[], int nvr, const string value[]);
  };

  /// create instance of <%modelShortName%>FMU
  static <%modelShortName%>FMU *createSystemFMU(IGlobalSettings *globalSettings);
  >>
end fmuModelHeaderFile;

template fmuModelCppFile(SimCode simCode,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, String guid, String FMUVersion)
 "Generates code for FMU target."
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(__)) then
  let modelName = dotPath(modelInfo.name)
  let modelShortName = lastIdentOfPath(modelInfo.name)
  let modelLongName = System.stringReplace(modelName, ".", "_")
  let algloopfiles = (listAppend(allEquations,initialEquations) |> eqs => algloopMainfile2(eqs, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, modelShortName) ;separator="\n")
  let solverFactory = match algloopfiles case "" then '' else
    'createStaticAlgLoopSolverFactory(globalSettings, PATH(""), PATH(""))'
  <<
  // define model identifier and unique id
  #define MODEL_IDENTIFIER <%modelLongName%>
  #define MODEL_IDENTIFIER_SHORT <%modelShortName%>
  #define MODEL_CLASS <%modelShortName%>FMU
  #define MODEL_GUID "{<%guid%>}"

  <%ModelDefineData(modelInfo)%>
  #define NUMBER_OF_EVENT_INDICATORS <%CodegenFMUCommon.getNumberOfEventIndicators(simCode)%>

  <%if isFMIVersion10(FMUVersion) then
    '#include <FMU/FMUWrapper.h>'
  else
    '#include "FMU2/FMU2Wrapper.cpp"'%>
  <%if isFMIVersion10(FMUVersion) then
    '#include <FMU/FMULibInterface.h>'
  else
    '#include "FMU2/FMU2Interface.cpp"'%>

  // SimObjects for <%modelShortName%>FMU
  shared_ptr<IAlgLoopSolverFactory> createStaticAlgLoopSolverFactory(IGlobalSettings*, PATH, PATH);

  class <%modelShortName%>SimObjects : public ISimObjects {
   public:
    <%modelShortName%>SimObjects(IGlobalSettings *globalSettings) {
      _algLoopSolverFactory = shared_ptr<IAlgLoopSolverFactory>(<%solverFactory%>);
    }
    weak_ptr<ISimData> LoadSimData(string modelKey) {
      return shared_ptr<ISimData>();
    }
    weak_ptr<ISimVars> LoadSimVars(string modelKey, size_t dim_real, size_t dim_int, size_t dim_bool, size_t dim_string, size_t dim_pre_vars, size_t dim_z, size_t z_i) {
      _simVars = shared_ptr<ISimVars>(new SimVars(dim_real, dim_int, dim_bool, dim_string, dim_pre_vars, dim_z, z_i));
      return _simVars;
    }
    weak_ptr<IHistory> LoadWriter(size_t) {
      return shared_ptr<IHistory>();
    }
    shared_ptr<ISimData> getSimData(string modelKey) {
      return shared_ptr<ISimData>();
    }
    shared_ptr<ISimVars> getSimVars(string modelKey) {
      return _simVars;
    }
    void eraseSimData(string modelKey) {}
    void eraseSimVars(string modelKey) {}
    shared_ptr<IAlgLoopSolverFactory> getAlgLoopSolverFactory() {
      return _algLoopSolverFactory;
    }
   protected:
    shared_ptr<ISimVars> _simVars;
    shared_ptr<IAlgLoopSolverFactory> _algLoopSolverFactory;
  };

  // create instance of <%modelShortName%>FMU
  <%modelShortName%>FMU *createSystemFMU(IGlobalSettings *globalSettings) {
    shared_ptr<ISimObjects> simObjects(new <%modelShortName%>SimObjects(globalSettings));
    simObjects->LoadSimVars("<%modelShortName%>", <%numRealvars(modelInfo)%>, <%numIntvars(modelInfo)%>, <%numBoolvars(modelInfo)%>, <%numStringvars(modelInfo)%>, <%getPreVarsCount(modelInfo)%>, <%numStatevars(modelInfo)%>, <%numStateVarIndex(modelInfo)%>);
    simObjects->LoadSimData("<%modelShortName%>");
    globalSettings->setOutputFormat(EMPTY);
    return new <%modelShortName%>FMU(globalSettings, simObjects);
  }

  // constructor
  <%modelShortName%>FMU::<%modelShortName%>FMU(IGlobalSettings* globalSettings, shared_ptr<ISimObjects> simObjects)
    : <%modelShortName%>Initialize(globalSettings, simObjects) {
  }

  // initialization
  void <%modelShortName%>FMU::initialize() {
    <%modelShortName%>WriteOutput::initialize();
    <%modelShortName%>Initialize::initializeMemory();
    <%modelShortName%>Initialize::initializeFreeVariables();
    <%modelShortName%>Jacobian::initialize();
    <%modelShortName%>Jacobian::initializeColoredJacobianA();
  }

  // getters
  <%if isFMIVersion10(FMUVersion) then accessFunctionsFMU1(simCode, "get", modelShortName, modelInfo) else accessFunctionsFMU2(simCode, "get", modelShortName, modelInfo)%>
  // setters
  <%if isFMIVersion10(FMUVersion) then accessFunctionsFMU1(simCode, "set", modelShortName, modelInfo) else accessFunctionsFMU2(simCode, "set", modelShortName, modelInfo)%>
  >>
  // TODO:
  // <%setDefaultStartValues(modelInfo)%>
  // <%setStartValues(modelInfo)%>
  // <%setExternalFunction(modelInfo)%>
end fmuModelCppFile;

template ModelDefineData(ModelInfo modelInfo)
 "Generates global data in simulation file."
::=
match modelInfo
case MODELINFO(varInfo=VARINFO(__), vars=SIMVARS(stateVars = listStates)) then
  <<
  /* TODO: implement external functions in FMU wrapper for c++ target
  <%System.tmpTickReset(0)%>
  <%(functions |> fn => defineExternalFunction(fn) ; separator="\n")%>
  */
  >>
end ModelDefineData;

template DefineVariables(SimVar simVar, Boolean useFlatArrayNotation)
 "Generates code for defining variables in c file for FMU target. "
::=
match simVar
  case SIMVAR(__) then
  let description = if comment then '// "<%comment%>"'
  if stringEq(crefStr(name),"$dummy") then
  <<>>
  else if stringEq(crefStr(name),"der($dummy)") then
  <<>>
  else
  <<
  #define <%cref(name,useFlatArrayNotation)%>_ <%System.tmpTick()%> <%description%>
  >>
end DefineVariables;

template defineExternalFunction(Function fn)
 "Generates external function definitions."
::=
  match fn
    case EXTERNAL_FUNCTION(dynamicLoad=true) then
      let fname = extFunctionName(extName, language)
      <<
      #define $P<%fname%> <%System.tmpTick()%>
      >>
end defineExternalFunction;


template setDefaultStartValues(ModelInfo modelInfo)
 "Generates code in c file for function setStartValues() which will set start values for all variables."
::=
match modelInfo
case MODELINFO(varInfo=VARINFO(numStateVars=numStateVars, numAlgVars= numAlgVars),vars=SIMVARS(__)) then
  <<
  // Set values for all variables that define a start value
  void setDefaultStartValues(ModelInstance *comp) {
  /*
  <%vars.stateVars |> var => initValsDefault(var,"realVars",0) ;separator="\n"%>
  <%vars.derivativeVars |> var => initValsDefault(var,"realVars",numStateVars) ;separator="\n"%>
  <%vars.algVars |> var => initValsDefault(var,"realVars",intMul(2,numStateVars)) ;separator="\n"%>
  <%vars.discreteAlgVars |> var => initValsDefault(var, "realVars", intAdd(intMul(2,numStateVars), numAlgVars)) ;separator="\n"%>
  <%vars.intAlgVars |> var => initValsDefault(var,"integerVars",0) ;separator="\n"%>
  <%vars.boolAlgVars |> var => initValsDefault(var,"booleanVars",0) ;separator="\n"%>
  <%vars.stringAlgVars |> var => initValsDefault(var,"stringVars",0) ;separator="\n"%>
  <%vars.paramVars |> var => initParamsDefault(var,"realParameter") ;separator="\n"%>
  <%vars.intParamVars |> var => initParamsDefault(var,"integerParameter") ;separator="\n"%>
  <%vars.boolParamVars |> var => initParamsDefault(var,"booleanParameter") ;separator="\n"%>
  <%vars.stringParamVars |> var => initParamsDefault(var,"stringParameter") ;separator="\n"%>
  */
  }
  >>
end setDefaultStartValues;

template setStartValues(ModelInfo modelInfo)
 "Generates code in c file for function setStartValues() which will set start values for all variables."
::=
match modelInfo
case MODELINFO(varInfo=VARINFO(numStateVars=numStateVars, numAlgVars= numAlgVars),vars=SIMVARS(__)) then
  <<
  // Set values for all variables that define a start value
  void setStartValues(ModelInstance *comp) {
  /*
  <%vars.stateVars |> var => initVals(var,"realVars",0) ;separator="\n"%>
  <%vars.derivativeVars |> var => initVals(var,"realVars",numStateVars) ;separator="\n"%>
  <%vars.algVars |> var => initVals(var,"realVars",intMul(2,numStateVars)) ;separator="\n"%>
  <%vars.discreteAlgVars |> var => initVals(var, "realVars", intAdd(intMul(2,numStateVars), numAlgVars)) ;separator="\n"%>
  <%vars.intAlgVars |> var => initVals(var,"integerVars",0) ;separator="\n"%>
  <%vars.boolAlgVars |> var => initVals(var,"booleanVars",0) ;separator="\n"%>
  <%vars.stringAlgVars |> var => initVals(var,"stringVars",0) ;separator="\n"%>
  <%vars.paramVars |> var => initParams(var,"realParameter") ;separator="\n"%>
  <%vars.intParamVars |> var => initParams(var,"integerParameter") ;separator="\n"%>
  <%vars.boolParamVars |> var => initParams(var,"booleanParameter") ;separator="\n"%>
  <%vars.stringParamVars |> var => initParams(var,"stringParameter") ;separator="\n"%>
  */
  }
  >>
end setStartValues;

template initVals(SimVar var, String arrayName, Integer offset) ::=
  match var
    case SIMVAR(__) then
    if stringEq(crefStr(name),"$dummy") then
    <<>>
    else if stringEq(crefStr(name),"der($dummy)") then
    <<>>
    else
    let str = 'comp->fmuData->modelData.<%arrayName%>Data[<%intAdd(index,offset)%>].attribute.start'
    <<
      <%str%> =  comp->fmuData->localData[0]-><%arrayName%>[<%intAdd(index,offset)%>];
    >>
end initVals;

template initParams(SimVar var, String arrayName) ::=
  match var
    case SIMVAR(__) then
    let str = 'comp->fmuData->modelData.<%arrayName%>Data[<%index%>].attribute.start'
      '<%str%> = comp->fmuData->simulationInfo.<%arrayName%>[<%index%>];'
end initParams;


template initValsDefault(SimVar var, String arrayName, Integer offset) ::=
  match var
    case SIMVAR(index=index, type_=type_) then
    let str = 'comp->fmuData->modelData.<%arrayName%>Data[<%intAdd(index,offset)%>].attribute.start'
    match initialValue
      case SOME(v) then
      '<%str%> = <%initVal(v)%>;'
      case NONE() then
        match type_
          case T_INTEGER(__)
          case T_REAL(__)
          case T_ENUMERATION(__)
          case T_BOOL(__) then '<%str%> = 0;'
          case T_STRING(__) then '<%str%> = "";'
          else 'UNKOWN_TYPE'
end initValsDefault;

template initParamsDefault(SimVar var, String arrayName) ::=
  match var
    case SIMVAR(__) then
    let str = 'comp->fmuData->modelData.<%arrayName%>Data[<%index%>].attribute.start'
    match initialValue
      case SOME(v) then
      '<%str%> = <%initVal(v)%>;'
end initParamsDefault;

template initVal(Exp initialValue)
::=
  match initialValue
  case ICONST(__) then integer
  case RCONST(__) then real
  case SCONST(__) then '"<%Util.escapeModelicaStringToXmlString(string)%>"'
  case BCONST(__) then if bool then "1" else "0"
  case ENUM_LITERAL(__) then '<%index%>/*ENUM:<%dotPath(name)%>*/'
  else "*ERROR* initial value of unknown type"
end initVal;


template setExternalFunction(ModelInfo modelInfo)
 "Generates setString function for c file."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
  let externalFuncs = setExternalFunctionsSwitch(functions)
  <<
  fmiStatus setExternalFunction(ModelInstance* c, const fmiValueReference vr, const void* value){
    switch (vr) {
    /*
        <%externalFuncs%>
    */
        default:
            return fmiError;
    }
    return fmiOK;
  }

  >>
end setExternalFunction;

template setExternalFunctionsSwitch(list<Function> functions)
 "Generates external function definitions."
::=
  (functions |> fn => setExternalFunctionSwitch(fn) ; separator="\n")
end setExternalFunctionsSwitch;

template setExternalFunctionSwitch(Function fn)
 "Generates external function definitions."
::=
  match fn
    case EXTERNAL_FUNCTION(dynamicLoad=true) then
      let fname = extFunctionName(extName, language)
      <<
      case $P<%fname%> : ptr_<%fname%>=(ptrT_<%fname%>)value; break;
      >>
end setExternalFunctionSwitch;

template accessFunctionsFMU1(SimCode simCode, String direction, String modelShortName, ModelInfo modelInfo)
 "Generates getters or setters for Real, Integer, Boolean, and String."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
  let qualifier = if stringEq(direction, "set") then "const"
  <<
  <%accessVarsFunctionFMU1(simCode, direction, modelShortName, "Real", "double", "_pointerToRealVars")%>
  <%accessVarsFunctionFMU1(simCode, direction, modelShortName, "Integer", "int", "_pointerToIntVars")%>
  <%accessVarsFunctionFMU1(simCode, direction, modelShortName, "Boolean", "int", "_pointerToBoolVars")%>

  void <%modelShortName%>FMU::<%direction%>String(const unsigned int vr[], int nvr, <%qualifier%> string value[]) {
  }
  >>
end accessFunctionsFMU1;

template accessVarsFunctionFMU1(SimCode simCode, String direction, String modelShortName, String typeName, String typeImpl, String arrayName)
 "Generates get<%typeName%> or set<%typeName%> function."
::=
  let qualifier = if stringEq(direction, "set") then "const"
  <<
  void <%modelShortName%>FMU::<%direction%><%typeName%>(const unsigned int vr[], int nvr, <%qualifier%> <%typeImpl%> value[]) {
    for (int i = 0; i < nvr; i++)
    {
      <%if stringEq(direction, "get") then
        'value[i] = <%arrayName%>[vr[i]];'
        else '<%arrayName%>[vr[i]] = value[i];'
      %>
    }
  }
  >>
end accessVarsFunctionFMU1;

template accessFunctionsFMU2(SimCode simCode, String direction, String modelShortName, ModelInfo modelInfo)
 "Generates getters or setters for Real, Integer, Boolean, and String."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__), varInfo=VARINFO(numStateVars=numStateVars, numAlgVars=numAlgVars, numDiscreteReal=numDiscreteReal, numParams=numParams)) then
  <<
  <%accessVarsFunctionFMU2(simCode, direction, modelShortName, "Real", "Real", "double", intAdd(intAdd(intAdd(intMul(2, numStateVars), numAlgVars), numDiscreteReal), numParams), vars.aliasVars)%>
  <%accessVarsFunctionFMU2(simCode, direction, modelShortName, "Integer", "Int", "int", intAdd(listLength(vars.intAlgVars), listLength(vars.intParamVars)), vars.intAliasVars)%>
  <%accessVarsFunctionFMU2(simCode, direction, modelShortName, "Boolean", "Bool", "int", intAdd(listLength(vars.boolAlgVars), listLength(vars.boolParamVars)), vars.boolAliasVars)%>
  <%accessVarsFunctionFMU2(simCode, direction, modelShortName, "String", "String", "string", intAdd(listLength(vars.stringAlgVars), listLength(vars.stringParamVars)), vars.stringAliasVars)%>
  >>
end accessFunctionsFMU2;

template accessVarsFunctionFMU2(SimCode simCode, String direction, String modelShortName, String typeName, String pointerName, String typeImpl, Integer offset, list<SimVar> aliasVars)
 "Generates get<%typeName%> or set<%typeName%> function."
::=
  let qualifier = if stringEq(direction, "set") then "const"
  <<
  void <%modelShortName%>FMU::<%direction%><%typeName%>(const unsigned int vr[], int nvr, <%qualifier%> <%typeImpl%> value[]) {
    for (int i = 0; i < nvr; i++, vr++, value++) {
      // access variables and aliases in SimVars memory
      if (*vr < _dim<%typeName%>)
        <%if stringEq(direction, "get") then
        <<
        *value = _pointerTo<%pointerName%>Vars[*vr];
        >>
        else
        <<
        _pointerTo<%pointerName%>Vars[*vr] = *value;
        >>%>
      // convert negated aliases
      else switch (*vr) {
        <%aliasVars |> var => accessVarFMU2(simCode, direction, var, offset); separator="\n"%>
        default:
          throw std::invalid_argument("<%direction%><%typeName%> with wrong value reference " + omcpp::to_string(*vr));
      }
    }
  }
  >>
end accessVarsFunctionFMU2;

template accessVarFMU2(SimCode simCode, String direction, SimVar simVar, Integer offset)
 "Generates a case statement accessing one variable."
::=
match simVar
  case SIMVAR(__) then
  let descName = System.stringReplace(crefStrNoUnderscore(name), "$", "_D_")
  let description = if comment then '/* <%descName%> "<%comment%>" */' else '/* <%descName%> */'
  let cppName = getCppName(simCode, simVar)
  let cppSign = getCppSign(simCode, simVar)
  if stringEq(direction, "get") then
  <<
  case <%intAdd(offset, index)%>: <%description%>
    *value = <%cppSign%><%cppName%>; break;
  >>
  else
  <<
  case <%intAdd(offset, index)%>: <%description%>
    <%cppName%> = <%cppSign%>*value; break;
  >>
end accessVarFMU2;

template getCppName(SimCode simCode, SimVar simVar)
  "Get name of variable in Cpp runtime, resolving aliases"
::=
match simVar
  case SIMVAR(__) then
    let actualName = cref1(name, simCode, "", "", "", contextOther, "", "", false)
    match aliasvar
      case ALIAS(__)
      case NEGATEDALIAS(__) then
        '<%cref1(varName, simCode, "", "", "", contextOther, "", "", false)%>'
      else
        '<%actualName%>'
end getCppName;

template getCppSign(SimCode simCode, SimVar simVar)
  "Get sign of variable in Cpp runtime, resolving aliases"
::=
match simVar
  case SIMVAR(type_=type_) then
    match aliasvar
      case NEGATEDALIAS(__) then
        match type_ case T_BOOL(__) then '!' else '-'
      else ''
end getCppSign;

template accessVecVarFMU2(String direction, SimVar simVar, Integer offset, String vecName)
 "Generates a case statement accessing one variable of a vector, neglecting $dummy state."
::=
match simVar
  case SIMVAR(__) then
  let descName = System.stringReplace(crefStrNoUnderscore(name), "$", "_D_")
  let description = if comment then '/* <%descName%> "<%comment%>" */' else '/* <%descName%> */'
  if stringEq(crefStr(name), "$dummy") then
  <<>>
  else if stringEq(crefStr(name), "der($dummy)") then
  <<>>
  else if stringEq(direction, "get") then
  <<
  case <%intAdd(offset, index)%>: <%description%>
    value[i] = <%vecName%>[<%index%>]; break;
  >>
  else
  <<
  case <%intAdd(offset, index)%>: <%description%>
    <%vecName%>[<%index%>] = value[i]; break;
  >>
end accessVecVarFMU2;

template fmuMakefile(String target, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, String FMUVersion, String additionalLinkerFlags_GCC,
                            String additionalLinkerFlags_MSVC, String additionalCFlags_GCC, String additionalCFlags_MSVC)
 "Generates the contents of the makefile for the simulation case. Copy libexpat & correct linux fmu"
::=
match target
case "msvc" then
match simCode
case SIMCODE(modelInfo=MODELINFO(__), makefileParams=MAKEFILE_PARAMS(__), simulationSettingsOpt = sopt) then
  let dirExtra = if modelInfo.directory then '-L"<%modelInfo.directory%>"' //else ""
  let libsStr = (makefileParams.libs |> lib => lib ;separator=" ")
  let libsPos1 = if not dirExtra then libsStr //else ""
  let libsPos2 = if dirExtra then libsStr // else ""
  let ParModelicaLibs = if acceptParModelicaGrammar() then '-lOMOCLRuntime -lOpenCL' // else ""
  let extraCflags = match sopt case SOME(s as SIMULATION_SETTINGS(__)) then
    match s.method case "dassljac" then "-D_OMC_JACOBIAN "

  <<
  # Makefile generated by OpenModelica

  # Simulations use -O3 by default
  SIM_OR_DYNLOAD_OPT_LEVEL=
  MODELICAUSERCFLAGS=
  CXX=cl
  EXEEXT=.exe
  DLLEXT=.dll
  include <%makefileParams.omhome%>/include/omc/cpp/ModelicaConfig_msvc.inc
  include <%makefileParams.omhome%>/include/omc/cpp/ModelicaLibraryConfig_msvc.inc
  # /Od - Optimization disabled
  # /EHa enable C++ EH (w/ SEH exceptions)
  # /fp:except - consider floating-point exceptions when generating code
  # /arch:SSE2 - enable use of instructions available with SSE2 enabled CPUs
  # /I - Include Directories
  # /DNOMINMAX - Define NOMINMAX (does what it says)
  # /TP - Use C++ Compiler
  CFLAGS=$(SYSTEM_CFLAGS) /w /I"<%makefileParams.omhome%>/include/omc/cpp/" /I"$(BOOST_INCLUDE)" /I"$(SUITESPARSE_INCLUDE)" /I. /TP /DNOMINMAX /DNO_INTERACTIVE_DEPENDENCY /DFMU_BUILD /DRUNTIME_STATIC_LINKING

  # /MD - link with MSVCRT.LIB
  # /link - [linker options and libraries]
  # /LIBPATH: - Directories where libs can be found
  LDFLAGS=/link /DLL /NOENTRY /LIBPATH:"<%makefileParams.omhome%>/lib/omc/cpp/msvc" /LIBPATH:"<%makefileParams.omhome%>/bin" OMCppSystem_FMU_static.lib OMCppMath_static.lib OMCppModelicaUtilities_static.lib OMCppExtensionUtilities_static.lib OMCppFMU_static.lib ModelicaExternalC.lib ModelicaStandardTables.lib $(BOOST_SYSTEM_LIB).lib
  PLATFORM="win32"

  MODELICA_SYSTEM_LIB=<%fileNamePrefix%>
  CALCHELPERMAINFILE=OMCpp$(MODELICA_SYSTEM_LIB)CalcHelperMain.cpp

  $(MODELICA_SYSTEM_LIB).fmu: $(MODELICA_SYSTEM_LIB)$(DLLEXT)
  <%\t%>rm -rf binaries
  <%\t%>mkdir -p "binaries/$(PLATFORM)"
  <%\t%>mv $(MODELICA_SYSTEM_LIB)$(DLLEXT) "binaries/$(PLATFORM)/"
  <%\t%>cp $(BOOST_LIBS)/$(BOOST_SYSTEM_LIB)$(DLLEXT) "binaries/$(PLATFORM)/"
  <%\t%>rm -f $(MODELICA_SYSTEM_LIB).fmu
  <%\t%>zip -r "$(MODELICA_SYSTEM_LIB).fmu" modelDescription.xml binaries
  <%\t%>rm -rf binaries

  $(MODELICA_SYSTEM_LIB)$(DLLEXT):
  <%\t%>$(CXX) /Fe$(MODELICA_SYSTEM_LIB)$(DLLEXT) $(CALCHELPERMAINFILE) $(CFLAGS) $(LDFLAGS)
  >>
end match
case "gcc" then
match simCode
case SIMCODE(modelInfo=MODELINFO(__), makefileParams=MAKEFILE_PARAMS(__), simulationSettingsOpt = sopt) then
  let dirExtra = if modelInfo.directory then '-L"<%modelInfo.directory%>"' //else ""
  let libsExtra = (makefileParams.libs |> lib => lib ;separator=" ")
  let extraCflags = match sopt case SOME(s as SIMULATION_SETTINGS(__)) then ""
  // Note: FMI 1.0 did not distinguish modelIdentifier from fileNamePrefix
  let modelName = if isFMIVersion10(FMUVersion) then fileNamePrefix else dotPath(modelInfo.name)
  let platformstr = match makefileParams.platform case "i386-pc-linux" then 'linux32' case "x86_64-linux" then 'linux64' else '<%makefileParams.platform%>'
  let mkdir = match makefileParams.platform case "win32" then '"mkdir.exe"' else 'mkdir'
  <<
  # Makefile generated by OpenModelica
  OMHOME=<%makefileParams.omhome%>
  include $(OMHOME)/include/omc/cpp/ModelicaConfig_gcc.inc
  include $(OMHOME)/include/omc/cpp/ModelicaLibraryConfig_gcc.inc
  # Simulations use -O0 by default; can be changed to e.g. -O2 or -Ofast
  SIM_OR_DYNLOAD_OPT_LEVEL=-O0
  CC=<%makefileParams.ccompiler%>
  CXX=<%makefileParams.cxxcompiler%>
  LINK=<%makefileParams.linker%>
  EXEEXT=<%makefileParams.exeext%>
  DLLEXT=<%makefileParams.dllext%>
  CFLAGS_BASED_ON_INIT_FILE=<%extraCflags%>

  FMU_CFLAGS=$(SYSTEM_CFLAGS:-O0=$(SIM_OR_DYNLOAD_OPT_LEVEL)) -DFMU_BUILD
  CFLAGS=$(CFLAGS_BASED_ON_INIT_FILE) -Winvalid-pch $(FMU_CFLAGS) -DRUNTIME_STATIC_LINKING -I"$(OMHOME)/include/omc/cpp" -I"$(UMFPACK_INCLUDE)" -I"$(SUNDIALS_INCLUDE)" -I"$(BOOST_INCLUDE)" <%makefileParams.includes ; separator=" "%> <%additionalCFlags_GCC%>

  ifeq ($(USE_LOGGER),ON)
  $(eval CFLAGS=$(CFLAGS) -DUSE_LOGGER)
  endif

  LDFLAGS=-L"$(OMHOME)/lib/<%getTriple()%>/omc/cpp" -L"$(BOOST_LIBS)" <%additionalLinkerFlags_GCC%> -Wl,--no-undefined
  PLATFORM="<%platformstr%>"

  CALCHELPERMAINFILE=OMCpp<%fileNamePrefix%>CalcHelperMain.cpp

  # CVode can be used for Co-Simulation FMUs, Kinsol is available to handle non linear equation systems
  OMCPP_SOLVER_LIBS=-lOMCppNewton_static
  ifeq ($(USE_FMU_SUNDIALS),ON)
  $(eval OMCPP_SOLVER_LIBS=$(OMCPP_SOLVER_LIBS) -lOMCppKinsol_static $(SUNDIALS_LIBRARIES))
  $(eval CFLAGS=-DENABLE_SUNDIALS_STATIC $(CFLAGS))
  endif

  CPPFLAGS = $(CFLAGS)

  OMCPP_LIBS=-lOMCppSystem_FMU_static -lOMCppMath_static -lOMCppExtensionUtilities_static -lOMCppModelicaUtilities_static -lOMCppFMU_static $(OMCPP_SOLVER_LIBS)

  MODELICA_EXTERNAL_LIBS=-lModelicaExternalC -lModelicaStandardTables -L$(LAPACK_LIBS) $(LAPACK_LIBRARIES)
  LIBS= $(OMCPP_LIBS) $(MODELICA_EXTERNAL_LIBS) $(BASE_LIB)

  # need boost system lib prior to C++11
  ifneq ($(findstring USE_CPP_ELEVEN,$(CFLAGS)),USE_CPP_ELEVEN)
    $(eval LIBS= $(LIBS) -l$(BOOST_SYSTEM_LIB))
  endif

  CPPFILES=$(CALCHELPERMAINFILE)
  OFILES=$(CPPFILES:.cpp=.o)

  .PHONY: <%modelName%>.fmu $(CPPFILES) clean

  <%modelName%>.fmu: $(OFILES)
  <%\t%>$(CXX) -shared -o <%fileNamePrefix%>$(DLLEXT) $(OFILES) $(LDFLAGS) $(LIBS)
  <%\t%>rm -rf binaries
  <%\t%><%mkdir%> -p "binaries/$(PLATFORM)"
  <%\t%>cp <%fileNamePrefix%>$(DLLEXT) "binaries/$(PLATFORM)/"
  ifeq ($(USE_FMU_SUNDIALS),ON)
  <%\t%>rm -rf documentation
  <%\t%><%mkdir%> -p "documentation"
  <%\t%>cp $(SUNDIALS_LIBRARIES_KINSOL) "binaries/$(PLATFORM)/"
  <%\t%>cp $(OMHOME)/share/omc/runtime/cpp/licenses/sundials.license "documentation/"
  endif
  <%\t%>rm -f <%modelName%>.fmu
  ifeq ($(USE_FMU_SUNDIALS),ON)
  <%\t%>zip -r "<%modelName%>.fmu" modelDescription.xml binaries documentation
  <%\t%>rm -rf documentation
  else
  <%\t%>zip -r "<%modelName%>.fmu" modelDescription.xml binaries
  endif
  <%\t%>rm -rf binaries

  clean:
  <%\t%>rm $(SRC) <%fileNamePrefix%>$(DLLEXT)

  >>
end fmuMakefile;

annotation(__OpenModelica_Interface="backend");
end CodegenFMUCpp;

// vim: filetype=susan sw=2 sts=2
