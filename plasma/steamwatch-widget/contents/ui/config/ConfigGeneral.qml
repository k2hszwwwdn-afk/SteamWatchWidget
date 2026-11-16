import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import QtQuick.Layouts
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: configPage

    property alias cfg_showArtwork: showArtwork.checked
    property bool cfg_showArtworkDefault: true
    property alias cfg_transparentBackground: transparentBackground.checked
    property bool cfg_transparentBackgroundDefault: false
    property alias cfg_textColor: textColorField.text
    property string cfg_textColorDefault: "#66c0f4"

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 8

        QQC2.CheckBox {
            id: showArtwork
            text: i18n("Show Steam game artwork")
        }

        QQC2.CheckBox {
            id: transparentBackground
            text: i18n("Transparent background")
        }

        QQC2.Label {
            text: i18n("Text and Play button color")
            Layout.topMargin: 8
        }

        RowLayout {
            Layout.fillWidth: true

            Rectangle {
                implicitWidth: 32
                implicitHeight: 32
                radius: 5
                color: textColorField.text
                border.color: palette.mid
            }

            QQC2.TextField {
                id: textColorField
                readOnly: true
                Layout.fillWidth: true
            }

            QQC2.Button {
                text: i18n("Choose color…")
                onClicked: colorDialog.open()
            }
        }
    }

    ColorDialog {
        id: colorDialog
        title: i18n("Choose widget color")
        selectedColor: configPage.cfg_textColor
        onAccepted: textColorField.text = Qt.rgba(
            selectedColor.r, selectedColor.g, selectedColor.b, 1
        ).toString()
    }
}
