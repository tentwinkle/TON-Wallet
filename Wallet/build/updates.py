import os, sys, re, subprocess, datetime, time

executePath = os.getcwd()
scriptPath = os.path.dirname(os.path.realpath(__file__))

filePrefix = 'wallet'
projectName = 'Wallet'
nameInCaption = 'GramWalletDesktop'
bundleId = 'org.ton.wallet.desktop.debug'

lastCommit = ''
today = ''
nextLast = False
nextDate = False
building = True
composing = False
for arg in sys.argv:
    if nextLast:
        lastCommit = arg
        nextLast = False
    elif nextDate:
        today = arg
        nextDate = False
    elif arg == 'send':
        building = False
        composing = False
    elif arg == 'from':
        nextLast = True
        building = False
        composing = True
    elif arg == 'date':
        nextDate = True

def finish(code, error = ''):
    if error != '':
        print('[ERROR] ' + error)
    global executePath
    os.chdir(executePath)
    sys.exit(code)

os.chdir(scriptPath + '/..')

if 'AC_USERNAME' not in os.environ:
    finish(1, 'AC_USERNAME not found!')
username = os.environ['AC_USERNAME']

if today == '':
    today = datetime.datetime.now().strftime("%d_%m_%y")
outputFolder = 'updates/' + today

archive = filePrefix + '_macOS_' + today + '.zip'

if building:
    print('Building debug version for OS X 10.12+..')

    if os.path.exists('../out/Debug/' + outputFolder):
        finish(1, 'Todays updates version exists.')

    result = subprocess.call('gyp/refresh.sh', shell=True)
    if result != 0:
        finish(1, 'While calling GYP.')

    result = subprocess.call('xcodebuild -project ' + projectName + '.xcodeproj -alltargets -configuration Debug build', shell=True)
    if result != 0:
        finish(1, 'While building ' + projectName + '.')

    os.chdir('../out/Debug')
    if not os.path.exists(projectName + '.app'):
        finish(1, projectName + '.app not found.')

    result = subprocess.call('strip ' + projectName + '.app/Contents/MacOS/' + projectName, shell=True)

    if result != 0:
        finish(1, 'While stripping ' + projectName + '.')

    result = subprocess.call('codesign --force --deep --timestamp --options runtime --sign "Developer ID Application: John Preston" ' + projectName + '.app --entitlements "../../' + projectName + '/Resources/mac/' + projectName + '.entitlements"', shell=True)
    if result != 0:
        finish(1, 'While signing ' + projectName + '.')

    if not os.path.exists(projectName + '.app/Contents/Resources/Icon.icns'):
        finish(1, 'Icon not found.')
    elif not os.path.exists(projectName + '.app/Contents/_CodeSignature'):
        finish(1, 'Signature not found.')

    if os.path.exists(today):
        subprocess.call('rm -rf ' + today, shell=True)
    subprocess.call('mkdir -p ' + today, shell=True)
    result = subprocess.call('cp -r ' + projectName + '.app ' + today + '/', shell=True)
    if result != 0:
        finish(1, 'Cloning ' + projectName + '.app to ' + today + '.')

    result = subprocess.call('zip -r ' + archive + ' ' + today, shell=True)
    if result != 0:
        finish(1, 'Adding ' + projectName + ' to archive.')

    print('Beginning notarization process.')
    lines = subprocess.check_output('xcrun altool --notarize-app --primary-bundle-id "' + bundleId + '" --username "' + username + '" --password "@keychain:AC_PASSWORD" --file "' + archive + '"', stderr=subprocess.STDOUT, shell=True)
    print('Response received.')
    uuid = ''
    for line in lines.split('\n'):
        parts = line.strip().split(' ')
        if len(parts) > 2 and parts[0] == 'RequestUUID':
            uuid = parts[2]
    if uuid == '':
        finish(1, 'Could not extract Request UUID. Response: ' + lines)
    print('Request UUID: ' + uuid)

    requestStatus = ''
    logUrl = ''
    while requestStatus == '':
        time.sleep(5)
        print('Checking...')
        lines = subprocess.check_output('xcrun altool --notarization-info "' + uuid + '" --username "' + username + '" --password "@keychain:AC_PASSWORD"', stderr=subprocess.STDOUT, shell=True)
        statusFound = False
        for line in lines.split('\n'):
            parts = line.strip().split(' ')
            if len(parts) > 1:
                if parts[0] == 'LogFileURL:':
                    logUrl = parts[1]
                elif parts[0] == 'Status:':
                    if parts[1] == 'in':
                        print('In progress.')
                        statusFound = True
                    else:
                        requestStatus = parts[1]
                        print('Status: ' + requestStatus)
                        statusFound = True
        if not statusFound:
            print('Nothing: ' + lines)
    if requestStatus != 'success':
        print('Notarization problems, response: ' + lines)
        if logUrl != '':
            print('Requesting log...')
            result = subprocess.call('curl ' + logUrl, shell=True)
            if result != 0:
                finish(1, 'Error calling curl ' + logUrl)
        finish(1, 'Notarization failed.')
    logLines = ''
    if logUrl != '':
        print('Requesting log...')
        logLines = subprocess.check_output('curl ' + logUrl, shell=True)
    result = subprocess.call('xcrun stapler staple ' + projectName + '.app', shell=True)
    if result != 0:
        finish(1, 'Error calling stapler')

    subprocess.call('rm -rf ' + today + '/' + projectName + '.app', shell=True)
    subprocess.call('rm ' + archive, shell=True)
    result = subprocess.call('cp -r ' + projectName + '.app ' + today + '/', shell=True)
    if result != 0:
        finish(1, 'Re-Cloning ' + projectName + '.app to ' + today + '.')

    result = subprocess.call('zip -r ' + archive + ' ' + today, shell=True)
    if result != 0:
        finish(1, 'Re-Adding ' + projectName + ' to archive.')
    print('Re-Archived.')

    subprocess.call('mkdir -p ' + outputFolder, shell=True)
    subprocess.call('mv ' + archive + ' ' + outputFolder + '/', shell=True)
    subprocess.call('rm -rf ' + today, shell=True)
    print('Finished.')

    if logLines != '':
        displayingLog = 0
        for line in logLines.split('\n'):
            if displayingLog == 1:
                print(line)
            else:
                parts = line.strip().split(' ')
                if len(parts) > 1 and parts[0] == '"issues":':
                    if parts[1] != 'null':
                        print('NB! Notarization log issues:')
                        print(line)
                        displayingLog = 1
                    else:
                        displayingLog = -1
        if displayingLog == 0:
            print('NB! Notarization issues not found: ' + logLines)
    else:
        print('NB! Notarization log not found.')
    finish(0)

commandPath = scriptPath + '/../../out/Debug/' + outputFolder + '/command.txt'

if composing:
    templatePath = scriptPath + '/../../../DesktopPrivate/updates_template.txt'
    if not os.path.exists(templatePath):
        finish(1, 'Template file "' + templatePath + '" not found.')

    if not re.match(r'^[a-f0-9]{5,40}$', lastCommit):
        finish(1, 'Wrong last commit: ' + lastCommit)

    log = subprocess.check_output(['git', 'log', lastCommit+'..HEAD'])
    logLines = log.split('\n')
    firstCommit = ''
    commits = []
    for line in logLines:
        if line.startswith('commit '):
            commit = line.split(' ')[1]
            if not len(firstCommit):
                firstCommit = commit
            commits.append('')
        elif line.startswith('    '):
            stripped = line[4:]
            if not len(stripped):
                continue
            elif not len(commits):
                print(log)
                finish(1, 'Bad git log output.')
            if len(commits[len(commits) - 1]):
                commits[len(commits) - 1] += '\n' + stripped
            else:
                commits[len(commits) - 1] = '- ' + stripped
    commits.reverse()
    if not len(commits):
        finish(1, 'No commits since last build :(')

    changelog = '\n'.join(commits)
    print('\n\nReady! File: ' + archive + '\nChangelog:\n' + changelog)
    with open(templatePath, 'r') as template:
        with open(commandPath, 'w') as f:
            for line in template:
                if line.startswith('//'):
                    continue
                line = line.replace('{path}', scriptPath + '/../../out/Debug/' + outputFolder + '/' + archive)
                line = line.replace('{caption}', nameInCaption + ' at ' + today.replace('_', '.') + ':\n\n' + changelog)
                f.write(line)
    print('\n\nEdit:\n')
    print('vi ' + commandPath)
    finish(0)

if not os.path.exists(commandPath):
    finish(1, 'Command file not found.')

readingCaption = False
caption = ''
with open(commandPath, 'r') as f:
    for line in f:
        if readingCaption:
            caption = caption + line
        elif line.startswith('caption: '):
            readingCaption = True
            caption = line[len('caption: '):]
            if not caption.startswith(nameInCaption + ' at ' + today.replace('_', '.') + ':'):
                finish(1, 'Wrong caption start.')
print('\n\nSending! File: ' + archive + '\nChangelog:\n' + caption)
if len(caption) > 1024:
    print('Length: ' + str(len(caption)))
    print('vi ' + commandPath)
    finish(1, 'Too large.')

if not os.path.exists('../out/Debug/' + outputFolder + '/' + archive):
    finish(1, 'Not built yet.')

subprocess.call(scriptPath + '/../../../tdesktop/out/Debug/Telegram.app/Contents/MacOS/Telegram -sendpath interpret://' + scriptPath + '/../../out/Debug/' + outputFolder + '/command.txt', shell=True)

finish(0)
