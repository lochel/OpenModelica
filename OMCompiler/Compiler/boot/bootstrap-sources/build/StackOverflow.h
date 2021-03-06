#ifndef StackOverflow__H
#define StackOverflow__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
void omc_StackOverflow_clearStacktraceMessages(threadData_t *threadData);
#define boxptr_StackOverflow_clearStacktraceMessages omc_StackOverflow_clearStacktraceMessages
static const MMC_DEFSTRUCTLIT(boxvar_lit_StackOverflow_clearStacktraceMessages,2,0) {(void*) boxptr_StackOverflow_clearStacktraceMessages,0}};
#define boxvar_StackOverflow_clearStacktraceMessages MMC_REFSTRUCTLIT(boxvar_lit_StackOverflow_clearStacktraceMessages)
extern void mmc_clearStacktraceMessages(OpenModelica_threadData_ThreadData*);
DLLExport
modelica_boolean omc_StackOverflow_hasStacktraceMessages(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_StackOverflow_hasStacktraceMessages(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StackOverflow_hasStacktraceMessages,2,0) {(void*) boxptr_StackOverflow_hasStacktraceMessages,0}};
#define boxvar_StackOverflow_hasStacktraceMessages MMC_REFSTRUCTLIT(boxvar_lit_StackOverflow_hasStacktraceMessages)
extern int mmc_hasStacktraceMessages(OpenModelica_threadData_ThreadData*);
DLLExport
void omc_StackOverflow_setStacktraceMessages(threadData_t *threadData, modelica_integer _numSkip, modelica_integer _numFrames);
DLLExport
void boxptr_StackOverflow_setStacktraceMessages(threadData_t *threadData, modelica_metatype _numSkip, modelica_metatype _numFrames);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StackOverflow_setStacktraceMessages,2,0) {(void*) boxptr_StackOverflow_setStacktraceMessages,0}};
#define boxvar_StackOverflow_setStacktraceMessages MMC_REFSTRUCTLIT(boxvar_lit_StackOverflow_setStacktraceMessages)
extern void mmc_setStacktraceMessages_threadData(OpenModelica_threadData_ThreadData*, int /*_numSkip*/, int /*_numFrames*/);
DLLExport
modelica_metatype omc_StackOverflow_getStacktraceMessages(threadData_t *threadData);
#define boxptr_StackOverflow_getStacktraceMessages omc_StackOverflow_getStacktraceMessages
static const MMC_DEFSTRUCTLIT(boxvar_lit_StackOverflow_getStacktraceMessages,2,0) {(void*) boxptr_StackOverflow_getStacktraceMessages,0}};
#define boxvar_StackOverflow_getStacktraceMessages MMC_REFSTRUCTLIT(boxvar_lit_StackOverflow_getStacktraceMessages)
extern modelica_metatype mmc_getStacktraceMessages_threadData(OpenModelica_threadData_ThreadData*);
DLLExport
modelica_metatype omc_StackOverflow_readableStacktraceMessages(threadData_t *threadData);
#define boxptr_StackOverflow_readableStacktraceMessages omc_StackOverflow_readableStacktraceMessages
static const MMC_DEFSTRUCTLIT(boxvar_lit_StackOverflow_readableStacktraceMessages,2,0) {(void*) boxptr_StackOverflow_readableStacktraceMessages,0}};
#define boxvar_StackOverflow_readableStacktraceMessages MMC_REFSTRUCTLIT(boxvar_lit_StackOverflow_readableStacktraceMessages)
DLLExport
modelica_string omc_StackOverflow_getReadableMessage(threadData_t *threadData, modelica_string _delimiter);
#define boxptr_StackOverflow_getReadableMessage omc_StackOverflow_getReadableMessage
static const MMC_DEFSTRUCTLIT(boxvar_lit_StackOverflow_getReadableMessage,2,0) {(void*) boxptr_StackOverflow_getReadableMessage,0}};
#define boxvar_StackOverflow_getReadableMessage MMC_REFSTRUCTLIT(boxvar_lit_StackOverflow_getReadableMessage)
DLLExport
modelica_string omc_StackOverflow_generateReadableMessage(threadData_t *threadData, modelica_integer _numFrames, modelica_integer _numSkip, modelica_string _delimiter);
DLLExport
modelica_metatype boxptr_StackOverflow_generateReadableMessage(threadData_t *threadData, modelica_metatype _numFrames, modelica_metatype _numSkip, modelica_metatype _delimiter);
static const MMC_DEFSTRUCTLIT(boxvar_lit_StackOverflow_generateReadableMessage,2,0) {(void*) boxptr_StackOverflow_generateReadableMessage,0}};
#define boxvar_StackOverflow_generateReadableMessage MMC_REFSTRUCTLIT(boxvar_lit_StackOverflow_generateReadableMessage)
DLLExport
void omc_StackOverflow_triggerStackOverflow(threadData_t *threadData);
#define boxptr_StackOverflow_triggerStackOverflow omc_StackOverflow_triggerStackOverflow
static const MMC_DEFSTRUCTLIT(boxvar_lit_StackOverflow_triggerStackOverflow,2,0) {(void*) boxptr_StackOverflow_triggerStackOverflow,0}};
#define boxvar_StackOverflow_triggerStackOverflow MMC_REFSTRUCTLIT(boxvar_lit_StackOverflow_triggerStackOverflow)
extern void mmc_do_stackoverflow(OpenModelica_threadData_ThreadData*);
#define boxptr_StackOverflow_stripAddresses omc_StackOverflow_stripAddresses
#define boxptr_StackOverflow_unmangle omc_StackOverflow_unmangle
#ifdef __cplusplus
}
#endif
#endif
