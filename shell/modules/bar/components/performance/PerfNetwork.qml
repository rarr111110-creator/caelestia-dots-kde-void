import QtQuick
import Caelestia.Services
import qs.components
import qs.services

PerfStat {
    readonly property real totalSpeed: (NetworkUsage.downloadSpeed ?? 0) + (NetworkUsage.uploadSpeed ?? 0)

    widthFactor: 3.5
    maxText: "999.9 MB/s"

    icon: "swap_vert"
    accent: Colours.palette.m3tertiary
    value: NaN
    valueText: {
        const fmt = NetworkUsage.formatBytesRate(totalSpeed);
        if (!fmt)
            return "0.0 B/s";
        return `${fmt.value.toFixed(1)} ${fmt.unit}`;
    }

    ServiceRef {
        service: NetworkUsage
    }
}
