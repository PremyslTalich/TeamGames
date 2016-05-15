import os
import json
import time
import tempfile
import subprocess
import collections

from CommentParser import ParseComment

includesDir = '../addons/sourcemod/scripting/include/'
outputFile = os.path.abspath('./output/include.json')
docParser = os.path.abspath('./docparse.exe')

def GetIncludeFileText(file):
    content = None
    with open(file, 'r') as f:
        content = f.read()
        
    return content
    
def GetIncludeFileData(file):
    jsonString = ''
    
    try:
        with open(os.devnull, 'w') as devnull:
            jsonString = subprocess.check_output(docParser + ' "' + file + '"', shell=True, stderr=devnull)
    except subprocess.CalledProcessError as err:
        print 'docparse.exe error: ' + str(err)
        return None
    
    return json.loads(jsonString)

def ProcessIncludeFileData(includeText, includeJson):
    for itemType, itemDict in includeJson.iteritems():
        for item in itemDict:
            if itemType == 'functions':
                if 'docStart' in item and 'docEnd' in item:
                    start = item['docEnd'] + includeText[item['docEnd']:].find('(') + 1
                    end = start + includeText[start:].find(')')
                    
                    args = [x.strip() for x in includeText[start:end].split(',')]
                    
                    for i, arg in enumerate(item['arguments']):
                        delimiter = args[i].find('=')
                        if delimiter != -1:
                            arg['defaultValue'] = args[i][delimiter + 1:].strip()
                            
                        if arg['type'].startswith('function '):
                            end = args[i].find(arg['name']) - 1
                            arg['type'] = args[i][:end].strip()
                
                for arg in item['arguments']:
                    if 'decl' in arg:
                        del arg['decl']
                        
                    if arg['type'][-1:] == '&':
                        arg['type'] = arg['type'][:-1]
                        arg['byReference'] = 1
            
            if itemType == 'enums':
                for subItem in item['entries']:
                    if 'docStart' in subItem and 'docEnd' in subItem:
                        comments = ParseComment(includeText[subItem['docStart']:subItem['docEnd']])

                        subItem['docText'] = comments.main.replace('\n', '<br/>')
                        
                        del subItem['docStart']
                        del subItem['docEnd']
                    
            if 'docStart' in item and 'docEnd' in item:
                comments = ParseComment(includeText[item['docStart']:item['docEnd']])
                item['docText'] = comments.main.replace('\n', '<br/>')
                
                if itemType == 'functions':
                    tags = dict(comments.tags)
                    
                    for arg in item['arguments']:
                        if 'param:' + arg['name'] in tags:
                            arg['docText'] = tags['param:' + arg['name']].replace('\n', '<br/>')
                    
                    if 'return' in tags:
                        item['returnDoc'] = tags['return']
                    else:
                        if item['returnType'] == 'int':
                            item['returnType'] = 'void'
                    
                if itemType == 'typedefs':
                    tags = dict(comments.tags)
                    fixedTags = []
                    
                    start = item['type'].find('(')
                    end = item['type'].find(')')
                    
                    argsText = item['type'][start + 1: end]
                    argsFull = [x.strip() for x in argsText.split(',')]
                    args = {}
                    
                    for arg in argsFull:
                        type = arg.split(' ', 1)[0]
                        name = arg.split(' ', 1)[1]
                        args[name] = type
                    
                    for arg in tags:
                        if arg.startswith('param:'):
                            singleArg = {}
                            singleArg['name'] = arg[6:]
                            singleArg['docText'] = tags[arg]
                            
                            if singleArg['name'] in args:
                                singleArg['type'] = args[singleArg['name']]
                            
                            fixedTags.append(singleArg)
                    
                    if fixedTags:
                        item['tags'] = fixedTags
                    
                del item['docStart']
                del item['docEnd']
    
    lines = [x.strip() for x in includeText.splitlines()]
    for line in lines:
        if line.lower().startswith('#define'):
            start = line.find(' ')
            end = line.find('/*')
            if end == -1:
                end = line.find('//')
            
            if end == -1:
                end = len(line)
            else:
                docText = line[end + 2:]
            
            line = line[start:end].strip()
            delimiter = line.find(' ')
            
            if delimiter == -1:
                continue
            
            constant = {}
            constant['name'] = line[:delimiter].strip()
            constant['value'] = line[delimiter:].strip()
            constant['docText'] = docText.strip()
            
            includeJson['constants'].append(constant)
    
    outData = {}
    
    for type in includeJson:
		for obj in includeJson[type]:
			if obj['name'] in outData:
				continue
			
			if obj['name'].endswith('SetNTVOptional'):
				continue
			
			objData = dict(obj)
			objData['objType'] = type
			del objData['name']
			
			outData[obj['name']] = objData
    
    return outData
    
if __name__ == '__main__':
    
    data = {}

    for file in os.listdir(includesDir):
        if file.endswith('.inc'):
            print file
            
            includeFilePath = os.path.abspath(includesDir + file)

            lines = []
            with open(includeFilePath, 'r') as includeFile:
                lines = includeFile.read().splitlines()

                for i, line in enumerate(lines):
                    if line.startswith('// typedef'):
                        lines[i] = line[3:]

                    if line.startswith('functag'):
                        lines[i] = '// ' + line
            
            tempIncludeFile = tempfile.NamedTemporaryFile(delete=False)
            tempIncludeFile.write('\n'.join(lines))
            tempIncludeFile.close()

            includeText = GetIncludeFileText(tempIncludeFile.name)
            includeJson = GetIncludeFileData(tempIncludeFile.name)
            
            os.unlink(tempIncludeFile.name)
            
            if includeText != None and includeJson != None:
                includeData = ProcessIncludeFileData(includeText, includeJson)
                data.update(includeData.items())
                
                print '  ' + 'Success !' + '\n'
            else:
                print '  ' + 'Error !' + '\n'
            
            
    if not data:
        sys.exit()
    
    oData = collections.OrderedDict(sorted(data.items()))
    
    outJson = ''
    outJson += 'var objects = ' + json.dumps(oData) + ';\n'
    
    if os.path.isfile(outputFile):
        os.rename(outputFile, outputFile[:-5] + '-' + str(int(time.time())) + outputFile[-5:])
    
    jsonOutput = open(outputFile, "w")
    jsonOutput.write(outJson)
    jsonOutput.close()