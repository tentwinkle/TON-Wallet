// This file is part of Gram Wallet Desktop,
// a desktop application for the TON Blockchain project.
//
// For license and copyright information please follow this link:
// https://github.com/ton-blockchain/wallet-desktop/blob/master/LEGAL
//
#pragma once

#include "core/base_integration.h"

namespace Updater {
class Instance;
struct Settings;
} // namespace Updater

namespace Core {

class Launcher {
public:
	Launcher(int argc, char *argv[]);
	virtual ~Launcher();

	static std::unique_ptr<Launcher> Create(int argc, char *argv[]);

	int exec();

	[[nodiscard]] QString argumentsString() const;
	[[nodiscard]] QString workingPath() const;
	[[nodiscard]] QString openedUrl() const;

	void startUpdateChecker();
	void restartForUpdater();
	[[nodiscard]] bool restartingForUpdater() const;
	[[nodiscard]] not_null<Updater::Instance*> updateChecker();
	[[nodiscard]] bool updateCheckerEnabled() const;
	void setUpdateCheckerEnabled(bool enabled);

private:
	enum class Action {
		Run,
		Cleanup,
		InstallUpdate,
	};
	void processArguments();
	void initAppDataPath();
	void initWorkingPath();
	void setupScale();
	[[nodiscard]] QString checkPortablePath();
	[[nodiscard]] QString computeWorkingPathBase();
	[[nodiscard]] bool canWorkInExecutablePath() const;

	QStringList readArguments(int argc, char *argv[]) const;

	void init();
	void cleanupInstallation();
	int executeApplication();

	[[nodiscard]] Updater::Settings updaterSettings() const;
	[[nodiscard]] QString updateCheckerDisabledFlagPath() const;

	int _argc = 0;
	char **_argv = nullptr;
	QStringList _arguments;
	Action _action = Action::Run;
	BaseIntegration _baseIntegration;

	std::unique_ptr<Updater::Instance> _updateChecker;
	bool _restartingForUpdater = false;
	QStringList _restartingArguments;

	QString _appDataPath;
	QString _workingPath;
	QString _openedUrl;

};

} // namespace Core
