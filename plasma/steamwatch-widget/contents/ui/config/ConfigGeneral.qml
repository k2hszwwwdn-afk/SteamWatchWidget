import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_showArtwork: showArtwork.checked
    property bool cfg_showArtworkDefault: true

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 8

        QQC2.CheckBox {
            id: showArtwork
            text: i18n("Show Steam game artwork")
        }
    }
}
