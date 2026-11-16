import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtCore
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: root

    property var games: []
    property var filteredGames: []
    property string searchText: ""
    property string scanError: ""
    property bool loading: true
    property string selectedGameId: ""
    property int refreshNonce: 0
    property color textColor: "#66c0f4"
    property bool transparentBackground: false
    property bool showArtwork: true
    property string scannerPath: decodeURIComponent(
        StandardPaths.writableLocation(StandardPaths.GenericDataLocation)
            .toString().replace(/^file:\/\//, "").replace(/\/$/, "")
    ) + "/steamwatch-widget/scan_games.py"
    readonly property string scannerSource: "/usr/bin/python3 "
        + shellQuote(scannerPath) + " --request " + refreshNonce

    Plasmoid.title: i18n("Steam Watch")
    Plasmoid.icon: "steam"
    Plasmoid.backgroundHints: root.transparentBackground
                              ? PlasmaCore.Types.NoBackground
                              : PlasmaCore.Types.DefaultBackground
    preferredRepresentation: fullRepresentation

    function shellQuote(value) {
        return "'" + value.replace(/'/g, "'\\''") + "'"
    }

    function refreshGames() {
        loading = true
        scanError = ""
        refreshNonce += 1
    }

    function reloadWidgetSettings() {
        textColor = Plasmoid.configuration.textColor || "#66c0f4"
        transparentBackground = Plasmoid.configuration.transparentBackground === true
                || Plasmoid.configuration.transparentBackground === "true"
        showArtwork = Plasmoid.configuration.showArtwork !== false
                && Plasmoid.configuration.showArtwork !== "false"
    }

    function updateFilteredGames() {
        var query = searchText.trim().toLocaleLowerCase()
        filteredGames = games.filter(function(game) {
            return game.name.toLocaleLowerCase().indexOf(query) !== -1
        })
        if (selectedGameId && !filteredGames.some(function(game) {
            return game.appid === selectedGameId
        })) {
            selectedGameId = ""
        }
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

    function selectedGame() {
        return games.find(function(game) {
            return game.appid === selectedGameId
        }) || null
    }

    function selectGame(appId) {
        selectedGameId = appId
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
                color: root.textColor
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
                color: root.textColor
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
                    text: i18n("Steam Games")
                    font.bold: true
                    font.pixelSize: 16
                    color: root.textColor
                }
                QQC2.ToolButton {
                    id: refreshButton
                    text: i18n("Refresh")
                    display: QQC2.AbstractButton.TextOnly
                    implicitWidth: 34
                    implicitHeight: 34
                    onClicked: root.refreshGames()
                    QQC2.ToolTip.text: i18n("Refresh game list")
                    QQC2.ToolTip.visible: hovered

                    contentItem: QQC2.Label {
                        text: "↻"
                        color: root.textColor
                        font.pixelSize: 24
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        radius: 6
                        color: refreshButton.hovered
                               ? Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.16)
                               : "transparent"
                    }
                }
            }

            QQC2.TextField {
                id: searchField
                Layout.fillWidth: true
                placeholderText: i18n("Search installed games")
                enabled: root.games.length > 0
                color: root.textColor
                placeholderTextColor: Qt.rgba(
                    root.textColor.r, root.textColor.g, root.textColor.b, 0.65
                )
                onTextChanged: {
                    root.searchText = text
                    root.updateFilteredGames()
                }
            }

            QQC2.ScrollView {
                id: gamesScrollView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: availableWidth

                QQC2.ScrollBar.vertical: QQC2.ScrollBar {
                    id: gamesScrollBar
                    parent: gamesScrollView
                    anchors.top: gamesScrollView.top
                    anchors.right: gamesScrollView.right
                    anchors.bottom: gamesScrollView.bottom

                    background: Rectangle {
                        color: root.transparentBackground
                               ? "transparent"
                               : Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.08)
                    }

                    contentItem: Rectangle {
                        implicitWidth: 6
                        radius: width / 2
                        color: Qt.rgba(
                            root.textColor.r, root.textColor.g, root.textColor.b,
                            root.transparentBackground ? 0.5 : 0.8
                        )
                    }
                }

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
                        color: modelData.appid === root.selectedGameId
                               ? Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.16)
                               : gameMouseArea.containsMouse
                                 ? Qt.rgba(1, 1, 1, 0.08)
                                 : "transparent"
                        border.width: modelData.appid === root.selectedGameId ? 1 : 0
                        border.color: root.textColor

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
                                    source: root.showArtwork
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
                                    color: root.textColor
                                    visible: coverArt.status !== Image.Ready
                                }
                            }

                            QQC2.Label {
                                Layout.fillWidth: true
                                text: modelData.name
                                color: root.textColor
                                elide: Text.ElideRight
                                maximumLineCount: 2
                                wrapMode: Text.Wrap
                            }
                        }

                        MouseArea {
                            id: gameMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectGame(modelData.appid)
                            onDoubleClicked: root.launchGame(modelData.appid)
                        }
                    }

                    QQC2.Label {
                        anchors.centerIn: parent
                        width: parent.width - 32
                        visible: !root.loading && root.scanError.length === 0
                                 && root.filteredGames.length === 0
                        text: root.games.length === 0
                              ? i18n("No installed Steam games found")
                              : i18n("No games match your search")
                        color: root.textColor
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                    }
                }
            }

            QQC2.Label {
                Layout.fillWidth: true
                visible: root.scanError.length > 0
                text: root.scanError
                color: root.textColor
                wrapMode: Text.Wrap
            }

            RowLayout {
                Layout.fillWidth: true
                QQC2.Label {
                    Layout.fillWidth: true
                    text: root.selectedGame()
                          ? i18n("Selected: %1", root.selectedGame().name)
                          : root.loading
                            ? i18n("Scanning Steam libraries…")
                            : i18np("%1 game", "%1 games", root.filteredGames.length)
                    color: root.textColor
                    opacity: 0.72
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 32

                Rectangle {
                    id: playHalo
                    anchors.fill: playButton
                    anchors.margins: -3
                    radius: 11
                    color: root.textColor
                    property real glowPulse: 0.34
                    opacity: playButton.enabled ? glowPulse : 0

                    SequentialAnimation on glowPulse {
                        running: playButton.enabled
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.52; duration: 850; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 0.28; duration: 850; easing.type: Easing.InOutSine }
                    }
                }

                QQC2.Button {
                    id: playButton
                    anchors.centerIn: parent
                    width: parent.width * 0.5
                    height: 28
                    text: i18n("SELECT")
                    enabled: root.selectedGame() !== null
                    onClicked: {
                        var game = root.selectedGame()
                        if (game) {
                            root.launchGame(game.appid)
                        }
                    }

                    background: Rectangle {
                        radius: 8
                        color: playButton.enabled
                               ? Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.18)
                               : Qt.rgba(1, 1, 1, 0.04)
                        border.width: 1
                        border.color: playButton.enabled
                                      ? root.textColor
                                      : Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.35)
                    }

                    contentItem: RowLayout {
                        spacing: 6
                        Item { Layout.fillWidth: true }
                        QQC2.Label {
                            text: "▶"
                            color: root.textColor
                            font.pixelSize: 14
                        }
                        QQC2.Label {
                            text: i18n("SELECT")
                            color: root.textColor
                            font.bold: true
                            font.letterSpacing: 0.8
                            elide: Text.ElideRight
                            Layout.maximumWidth: parent.width * 0.6
                        }
                        Item { Layout.fillWidth: true }
                    }
                }
            }
        }
    }

    Timer {
        interval: 250
        repeat: true
        running: true
        onTriggered: root.reloadWidgetSettings()
    }

    Component.onCompleted: {
        reloadWidgetSettings()
        refreshGames()
    }
}
