import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtCore
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: root

    property var games: []
    property var filteredGames: []
    property string searchText: ""
    property string scanError: ""
    property bool loading: true
    property int refreshNonce: 0
    property string scannerPath: decodeURIComponent(
        StandardPaths.writableLocation(StandardPaths.GenericDataLocation)
            .toString().replace(/^file:\/\//, "").replace(/\/$/, "")
    ) + "/steamwatch-widget/scan_games.py"
    readonly property string scannerSource: "/usr/bin/python3 "
        + shellQuote(scannerPath) + " --request " + refreshNonce

    Plasmoid.title: i18n("Steam Watch")
    Plasmoid.icon: "steam"
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground
    preferredRepresentation: fullRepresentation

    function shellQuote(value) {
        return "'" + value.replace(/'/g, "'\\''") + "'"
    }

    function refreshGames() {
        loading = true
        scanError = ""
        refreshNonce += 1
    }

    function updateFilteredGames() {
        var query = searchText.trim().toLocaleLowerCase()
        filteredGames = games.filter(function(game) {
            return game.name.toLocaleLowerCase().indexOf(query) !== -1
        })
    }

    function acceptScan(data) {
        loading = false
        if (data["exit code"] !== 0) {
            scanError = data.stderr || i18n("The Steam game scanner could not run.")
            games = []
            updateFilteredGames()
            return
        }

        var result
        try {
            result = JSON.parse(data.stdout || "")
        } catch (error) {
            scanError = i18n("Could not read the scanner response: %1", error)
            games = []
            updateFilteredGames()
            return
        }

        if (!result || !Array.isArray(result.games) || typeof result.error !== "string") {
            scanError = i18n("The scanner returned invalid game data.")
            games = []
            updateFilteredGames()
            return
        }

        games = result.games.filter(function(game) {
            return game && /^[0-9]+$/.test(game.appid) && typeof game.name === "string"
        })
        scanError = result.error
        updateFilteredGames()
    }

    function launchGame(appId) {
        if (!Qt.openUrlExternally("steam://rungameid/" + appId)) {
            scanError = i18n("Steam could not be opened. Check your Steam installation.")
        }
    }

    Plasma5Support.DataSource {
        id: scanner
        engine: "executable"
        interval: 30000
        connectedSources: [root.scannerSource]

        onNewData: function(sourceName, data) {
            if (sourceName === root.scannerSource) {
                root.acceptScan(data)
            }
        }
    }

    compactRepresentation: Item {
        implicitWidth: 150
        implicitHeight: 36

        RowLayout {
            anchors.fill: parent
            spacing: 6

            QQC2.Label {
                text: "S"
                color: "#66c0f4"
                font.bold: true
                font.pixelSize: 22
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            QQC2.Label {
                Layout.fillWidth: true
                text: root.loading
                      ? i18n("Steam Games…")
                      : i18np("Steam · %1 game", "Steam · %1 games", root.games.length)
                elide: Text.ElideRight
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.expanded = !root.expanded
        }
    }

    fullRepresentation: Item {
        implicitWidth: 380
        implicitHeight: 480
        Layout.minimumWidth: 280
        Layout.minimumHeight: 280

        ColumnLayout {
            anchors.fill: parent
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                QQC2.Label {
                    Layout.fillWidth: true
                    text: i18n("Installed Steam Games")
                    font.bold: true
                    font.pixelSize: 16
                }
                QQC2.ToolButton {
                    icon.name: "view-refresh"
                    text: i18n("Refresh")
                    display: QQC2.AbstractButton.IconOnly
                    onClicked: root.refreshGames()
                    QQC2.ToolTip.text: i18n("Refresh game list")
                    QQC2.ToolTip.visible: hovered
                }
            }

            QQC2.TextField {
                id: searchField
                Layout.fillWidth: true
                placeholderText: i18n("Search installed games")
                enabled: root.games.length > 0
                onTextChanged: {
                    root.searchText = text
                    root.updateFilteredGames()
                }
            }

            QQC2.ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: availableWidth

                ListView {
                    id: gameList
                    model: root.filteredGames
                    spacing: 4
                    clip: true
                    reuseItems: true

                    delegate: Rectangle {
                        required property var modelData
                        width: gameList.width
                        height: 64
                        radius: 8
                        color: gameMouseArea.containsMouse
                               ? Qt.rgba(1, 1, 1, 0.08)
                               : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 10

                            Rectangle {
                                Layout.preferredWidth: 48
                                Layout.preferredHeight: 52
                                radius: 5
                                color: Qt.rgba(1, 1, 1, 0.08)
                                clip: true

                                Image {
                                    id: coverArt
                                    anchors.fill: parent
                                    source: Plasmoid.configuration.showArtwork
                                           && modelData.artworkPath
                                           ? encodeURI("file://" + modelData.artworkPath)
                                           : ""
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    visible: status === Image.Ready
                                }

                                QQC2.Label {
                                    anchors.centerIn: parent
                                    text: modelData.name.substring(0, 1).toUpperCase()
                                    font.bold: true
                                    font.pixelSize: 22
                                    visible: coverArt.status !== Image.Ready
                                }
                            }

                            QQC2.Label {
                                Layout.fillWidth: true
                                text: modelData.name
                                elide: Text.ElideRight
                                maximumLineCount: 2
                                wrapMode: Text.Wrap
                            }

                            QQC2.Button {
                                text: i18n("Play")
                                icon.name: "media-playback-start"
                                onClicked: root.launchGame(modelData.appid)
                            }
                        }

                        MouseArea {
                            id: gameMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
                        }
                    }

                    PlasmaExtras.PlaceholderMessage {
                        anchors.centerIn: parent
                        width: parent.width - 32
                        visible: !root.loading && root.scanError.length === 0
                                 && root.filteredGames.length === 0
                        iconName: "steam"
                        text: root.games.length === 0
                              ? i18n("No installed Steam games found")
                              : i18n("No games match your search")
                    }
                }
            }

            QQC2.Label {
                Layout.fillWidth: true
                visible: root.scanError.length > 0
                text: root.scanError
                color: "#e05a5a"
                wrapMode: Text.Wrap
            }

            RowLayout {
                Layout.fillWidth: true
                QQC2.Label {
                    Layout.fillWidth: true
                    text: root.loading
                          ? i18n("Scanning Steam libraries…")
                          : i18np("%1 game", "%1 games", root.filteredGames.length)
                    opacity: 0.72
                }
            }
        }
    }

    Component.onCompleted: refreshGames()
}
