#pragma once

#include "../Settings/objectnode.hpp"
#include "common.hpp"

#include <QFileInfo>
#include <QStandardPaths>

namespace caelestia::config {

using Qt::StringLiterals::operator""_s;
using settings::vmap;
using settings::vmap;

class GeneralApps : public settings::ObjectNode {
    CONFIG_NODE(GeneralApps, settings::ObjectNode)

    CONFIG_GLOBAL_PROPERTY(QStringList, terminal, { u"foot"_s })
    CONFIG_GLOBAL_PROPERTY(QStringList, audio, { u"xdg-open"_s })
    CONFIG_GLOBAL_PROPERTY(QStringList, playback, { u"xdg-open"_s })
    CONFIG_GLOBAL_PROPERTY(QStringList, explorer, { u"xdg-open"_s })
};

class GeneralIdle : public settings::ObjectNode {
    CONFIG_NODE(GeneralIdle, settings::ObjectNode)

    CONFIG_GLOBAL_PROPERTY(bool, lockBeforeSleep, true)
    CONFIG_GLOBAL_PROPERTY(bool, inhibitWhenAudio, true)
    CONFIG_GLOBAL_PROPERTY(bool, inhibitWhenCharging, false)
    CONFIG_GLOBAL_PROPERTY(QVariantList, timeouts,
        DEFAULT_ARG({
            vmap({
                { u"timeout"_s, 180 },
                { u"idleAction"_s, u"lock"_s },
            }),
            vmap({
                { u"timeout"_s, 300 },
                { u"idleAction"_s, u"dpms off"_s },
                { u"returnAction"_s, u"dpms on"_s },
            }),
            vmap({
                { u"timeout"_s, 600 },
                { u"idleAction"_s, QStringList{ u"suspendThenHibernate"_s } },
                { u"enabled"_s, false },
            }),
        }))
};

class GeneralBattery : public settings::ObjectNode {
    CONFIG_NODE(GeneralBattery, settings::ObjectNode)

    CONFIG_GLOBAL_PROPERTY(QVariantList, warnLevels,
        DEFAULT_ARG({
            vmap({
                { u"level"_s, 20 },
                { u"title"_s, u"Low battery"_s },
                { u"message"_s, u"You might want to plug in a charger"_s },
                { u"icon"_s, u"battery_android_frame_2"_s },
            }),
            vmap({
                { u"level"_s, 10 },
                { u"title"_s, u"Did you see the previous message?"_s },
                { u"message"_s, u"You should probably plug in a charger <b>now</b>"_s },
                { u"icon"_s, u"battery_android_frame_1"_s },
            }),
            vmap({
                { u"level"_s, 5 },
                { u"title"_s, u"Critical battery level"_s },
                { u"message"_s, u"PLUG THE CHARGER RIGHT NOW!!"_s },
                { u"icon"_s, u"battery_android_alert"_s },
                { u"critical"_s, true },
            }),
        }))
    CONFIG_GLOBAL_PROPERTY(int, criticalLevel, 3)
};

class GeneralConfig : public settings::ObjectNode {
    CONFIG_NODE(GeneralConfig, settings::ObjectNode)

    CONFIG_GLOBAL_PROPERTY(QString, logo, QString())
    CONFIG_PROPERTY(bool, showOverFullscreen, false)
    CONFIG_PROPERTY(qreal, mediaGifSpeedAdjustment, 300)
    CONFIG_PROPERTY(qreal, sessionGifSpeed, 0.7)
    CONFIG_PROPERTY(QString, language, "system")
    CONFIG_PROPERTY(bool, debugLogs, false)
    CONFIG_PROPERTY(bool, checkUpdates, true)
    CONFIG_PROPERTY(bool, magicLampEnabled, true)
    CONFIG_PROPERTY(bool, caelestiaMode, false)
    CONFIG_PROPERTY(bool, krohnkiteEnabled, false)
    CONFIG_PROPERTY(QString, krohnkiteLastLayout, "BTree")
    CONFIG_SUBOBJECT(GeneralApps, apps)
    CONFIG_SUBOBJECT(GeneralIdle, idle)
    CONFIG_SUBOBJECT(GeneralBattery, battery)
};

} // namespace caelestia::config
