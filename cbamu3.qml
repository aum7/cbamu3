// mu3 plugin
import MuseScore 3.0
import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Window 2.2

MuseScore {
  id: cbamu3plugin
  version: "1.0"
  description: qsTr("chromatic button accordion")
  pluginType: "dialog"
  // title: qsTr("chromatic button accordion plugin")
  width: 300
  height: 840 
  
  onRun: {
    console.log("cba plugin started")
  }
  
  property bool showButtonboard: true 
  property int comboWidth: 110
  
  readonly property color highlight1b: "dodgerblue"
  readonly property color highlight2g: "darkgreen"
  
  property var trebleActivePitches: []
  property var bassActivePitches: []
  
  property bool meloBassMode: false
  property bool showButtonTones: true 
  property bool showFingering: false
  // fingering checkbox double-click
  property var lastClickTime: 0
  property bool showTreble: false
  
  property int bassOctaveShift
  
  property int rowLeftMargin: 7
  property int textLeftPadding: 19 
  property int tooltipDelay: 999
  
  property int buttonSize: 36 
  property int buttonSpacing: 4
  property int buttonFontSize: 34 
  
  property var bassBtnSize: 36
  property var bassBtnSpacing: 3
  property var bassBtnFontSize: 34
  
  property var layouts: [
    { name: "C-griff Europe",start: 55, offset: [0, -1, 1, 0, 2] }, 
    { name: "C-griff 2", start: 56, offset: [3, 1, 2, 0, 1] },
    { name: "B-griff Bayan", start: 55, offset: [3, 1, 2, 0, 1] }, 
    { name: "B-griff Finland", start: 55, offset: [1, 0, 2, 1, 3] },
    { name: "D-griff 1", start: 53, offset: [1, 0, 2, 1, 3] },
    { name: "D-griff 2", start: 55, offset: [2, 0, 1, -1, 0] }
  ]
  property var selectedLayout: layouts[0]
  
  property var bassLayouts: [
    { name: "minor 3rds",start: 54, offset: [0, 1, 2, 3, 4], vStep: 3 },
    { name: "Bayan", start: 54, offset: [29, 28, 27, 26, 4], vStep: -3 },
    { name: "5ths", start: 54, offset: [24, 28, 12, 16, 4], vStep: 5 },
    { name: "N. Europe", start: 54, offset: [-1, 1, 3, 5, 4], vStep: 3 },
    { name: "Finnish", start: 54, offset: [-1, 0, 1, 2, 4], vStep: 3 },
  ]
  property var selectedBassLayout: bassLayouts[0]
  
  readonly property var chordMap: {
    "145":  "",       
    "137":  "m",      
    "273":  "aug",    
    "73":   "dim",    
    "585":  "dim7",   
    "1169": "7",      
    "1041": "7",      
    "2193": "Maj7",   
    "2065": "Maj7",   
    "1161": "m7",     
    "1033": "m7",     
    "1097": "m7b5",   
    "657":  "6",      
    "649":  "m6",     
    "1173": "9",      
    "161":  "sus4",   
    "141":  "sus2",   
    "1185": "7sus4"   
  }
  
  Timer {
    interval: 200
    running: true
    repeat: true
    property string lastTonality: ""
    onTriggered: {
      if (!curScore) return
      var elements = curScore.selection.elements
      var tempTreble = []
      var tempBass = []
      var bassPitches = []
      var bassSolo = false
      var foundChordTonality = "" 
      
      for (var i = 0; i < elements.length; i++) {
        if (elements[i].type === Element.NOTE) {
          var pitch = elements[i].pitch
          var track = elements[i].track
          var text = elements[i].parent
          if (track >= 0 && track < 4) {
            showTreble = true
            if (tempTreble.indexOf(pitch) === -1) {
              tempTreble.push(pitch)
            }
          } else if (track >= 4 && track < 8) {
            showTreble = false
            if (bassPitches.indexOf(pitch) === -1) {
              bassPitches.push(pitch)
            }
            if (text && text.parent) {
              var seg = text.parent
              if (seg.annotations) {
                for (var j = 0; j < seg.annotations.length; j++) {
                  var ann = seg.annotations[j]
                  if (ann.type === Element.STAFF_TEXT) {
                    var annTxt = ann.text.trim()
                    var annTxtLower = annTxt.toLowerCase().replace(/\./g, "")
                    if (annTxtLower === "sb" || annTxtLower === "bs") {
                      bassSolo = true
                      console.log("bassSolo !")
                    } else if (annTxt === "M" || annTxt === "m" || 
                      // store M m 7 o if found as staff text above single bass note above D3
                      annTxt === "7" || annTxt === "o") {
                      foundChordTonality = annTxt
                    } else {
                      // get chord from chord marking above note(s)
                      var chordMatch = annTxt.match(/^[A-G][#b♮♯♭]?(.*)$/i)
                      if (chordMatch) {
                        var suffix = chordMatch[1].trim().toLowerCase()
                        if (suffix.indexOf("dim") !== -1 || suffix.indexOf("o") !== -1) {
                          foundChordTonality = "o"
                        } else if (suffix.indexOf("7") !== -1 || suffix.indexOf("9") !== -1) {
                          foundChordTonality = "7"
                        } else if (suffix.indexOf("m") === 0 || suffix.indexOf("min") === 0) {
                          foundChordTonality = "m"
                        } else if (suffix === "" || suffix.indexOf("maj") === 0 ||
                          suffix === "M") {
                          foundChordTonality = "M"
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
      if (foundChordTonality !== "") {
        console.log("tonality=" + foundChordTonality)
        lastTonality = foundChordTonality
      } else {
        foundChordTonality = lastTonality
      }
      if (meloBassMode) {
        for (var i = 0; i < bassPitches.length; i++) {
          var targetPitch = bassPitches[i] - bassOctaveShift
          for (var r = 0; r < 12; r++) {
            for (var c = 0; c < 4; c++) {
              if (mapMelodicBass(r, c) === targetPitch) {
                tempBass.push(r + "," + c)
              }
            }
          }
        }
      } else {
        if (bassSolo) {
        for (var i = 0; i < bassPitches.length; i++) {
          var targetPitchClass = bassPitches[i] % 12
          for (var r = 0; r < 12; r++) {
            if (((42 + r * 5) % 12) === targetPitchClass) tempBass.push(r + ",4")
            if (((42 + r * 5 + 4) % 12) === targetPitchClass) tempBass.push(r + ",5")
          }
        }
      } else if (foundChordTonality !== "" && bassPitches.length === 1
        && bassPitches[0] >= 50) {
        var targetCol = -1
        if (foundChordTonality === "o") targetCol = 0
        else if (foundChordTonality === "7") targetCol = 1
        else if (foundChordTonality === "m") targetCol = 2
        else if (foundChordTonality === "M") targetCol = 3
        var targetPitchClass = bassPitches[0] % 12
        for (var r = 0; r < 12; r++) {
          var fbPitchClass = (42 + r * 5) % 12
          if (fbPitchClass === targetPitchClass) {
            if (targetCol !== -1) {
              tempBass.push(r + "," + targetCol)
            }
            tempBass.push(r + ",4")
            tempBass.push(r + 4 + ",5")
          }
        }
      } else {
        var singleNotes = []
        var chordNotes = []
        for (var i = 0; i < bassPitches.length; i++) {
          if (bassPitches[i] <= 50) {
            singleNotes.push(bassPitches[i])
          } else {
            chordNotes.push(bassPitches[i])
          }
        }
        for (var i = 0; i < singleNotes.length; i++) {
          var targetPitchClass = singleNotes[i] % 12
          for (var r = 0; r < 12; r++) {
            if (((42 + r * 5) %12) === targetPitchClass) tempBass.push(r + ",4")
            if (((42 + r * 5 + 4) % 12) === targetPitchClass) tempBass.push(r + ",5")
          }
        }
        if (chordNotes.length >= 3 || 
          (chordNotes.length > 0 && bassPitches.length >= 3)) {
          var notesToDetect = chordNotes.length >= 3 ? chordNotes : bassPitches
          notesToDetect.sort(function(a, b) { return a - b })
          var normalized = []
          for (var k = 0; k < notesToDetect.length; k++) {
            var p = notesToDetect[k] % 12
            if (normalized.indexOf(p) === -1) normalized.push(p)
          }
          var foundChordCol = -1
          var rootNoteClass = -1
          for (var n = 0; n < normalized.length; n++) {
            var root = normalized[n]
            var mask = 0
            for (var j = 0; j < normalized.length; j++) {
              var interval = (normalized[j] - root + 12) % 12
              mask |= (1 << interval)
            }
            if (chordMap[mask] !== undefined) {
              var suffix = chordMap[mask]
              rootNoteClass = root
              if (suffix === "dim" || suffix === "dim7") foundChordCol = 0
              else if (suffix === "7" || suffix === "9") foundChordCol = 1
              else if (suffix === "m" || suffix === "m6" || suffix === "m7") 
                foundChordCol = 2 
              else if (suffix === "" || suffix === "Maj7") foundChordCol = 3 
              break
            }
          }
          if (rootNoteClass !== -1) {
            for (var r = 0; r < 12; r++) {
              var fbPitchClass = (42 + r * 5) % 12
              if (fbPitchClass === rootNoteClass) {
                if (foundChordCol !== -1) {
                  tempBass.push(r + "," + foundChordCol)
                }
              }
            }
          }
        } else if (bassPitches.length === 1) {
          var targetPitchClass = bassPitches[0] % 12
          for (var r = 0; r < 12; r++) {
            if (((42 + r * 5) % 12) === targetPitchClass) tempBass.push(r + ",4")
            if (((42 + r * 5 + 4) % 12) === targetPitchClass) tempBass.push(r + ",5")
          }
        }
      } 
    }  
    trebleActivePitches = tempTreble
    bassActivePitches = tempBass
    }
  }

  function hideFinger() {
    console.log("dbg : inside hideFinger ...")
    // hide fingering markings on treble staff
    if (!curScore || curScore.selection.elements.length === 0) return
    // start command
    curScore.startCmd()
    // create cursor for navigation of score
    var elements = curScore.selection.elements
    var count = 0
    for (var i = 0; i < elements.length; i++) {
      var note = elements[i]
      if (note.type != Element.NOTE) continue
      var existing = getExistingFinger(note)
      if (existing) {
        existing.visible = false
        count++
      }
    }
    // console.log("hideFinger : endTick=", endTick)
    // end command
    curScore.endCmd()
    console.log("hideFinger : count=", count)
  }

  function getExistingFinger(note) {
    for (var i = 0; i < note.elements.length; i++) {
      if (note.elements[i].type == Element.FINGERING) return note.elements[i]
    }
    return null
  }

  function calcFinger(requestAlternate) {
    var selectedRange = curScore.selection.elements.length
    console.log("calcFinger : selected=", selectedRange, " | requestAlternate=", requestAlternate)
    if (!curScore || curScore.selection.elements.length === 0) return
    // wrap into command
    curScore.startCmd()
    var startTick = curScore.selection.startSegment.tick
    var endTick = curScore.selection.endSegment.tick
    console.log("calcFinger : selection start=", startTick, " | end=", endTick)
    // gather melody line data
    var notesSequence = []
    var cursor = curScore.newCursor()
    cursor.rewind(Cursor.SELECTION_START) // todo score_start
    while (cursor.segment && cursor.tick < endTick) {
      if (cursor.tick >= startTick && 
        cursor.element && cursor.element.type == Element.CHORD) {
        var chord = cursor.element
        // console.log("dbg : found chord at : ", cursor.tick, " | notes=", chord.notes.length)
        if (chord.notes.length > 0) {
          // top note
          var topNote = chord.notes[chord.notes.length - 1]
          // focus on primary melody note : top one if chord
          notesSequence.push({
            pitch: topNote.pitch,
            noteElement: topNote,
            // chordElement: chord, // track parent for later
            tick: cursor.tick
          })
          // console.log("dbg : note added to seq | pitch=", topNote.pitch)
        }
      }
      cursor.next()
    }
    // process
    console.log("dbg : notes found=", notesSequence.length)
    var textCount = 0
    // sequential evaluation loop
    for (var i = 0; i < notesSequence.length; i++) {
      var current = notesSequence[i]
      var note = current.noteElement
      var existing = getExistingFinger(note)
      if (existing) {
        existing.visible = true
      } else {
        var prev = (i > 0) ? notesSequence[i - 1] : null
        var next = (i < notesSequence.length - 1) ? notesSequence[i + 1] : null
      // detect direction for closer-to rule parsing
        var direction = 0 // 0=stable 1=higher note next -1=lower note next
        if (next) {
          if (next.pitch > current.pitch) direction = 1
          else if (next.pitch < current.pitch) direction = -1
        }
        // lookahead to catch 3-note chromatic run
        var isChromatic = (next && prev) &&
          (Math.abs(current.pitch - prev.pitch) == 1 && 
          Math.abs(next.pitch - current.pitch) == 1)
        // run internal logic engines
        var fingerText = newElement(Element.FINGERING)
        fingerText.text = getFinger(current.pitch, direction, isChromatic, requestAlternate)
        // console.log("dbg : applying to pitch ", current.pitch, 
        //   "dir=", direction, "chromatic=", isChromatic)
        // insert stacked fingerings onto score
        fingerText.placement = Placement.ABOVE
        // console.log("-------- fingerText=", fingerText)
        note.add(fingerText)
        // console.log("dbg : applied fingering=", fingerText)
        textCount++
      }
    }
    curScore.endCmd()
    console.log("calcFinger : textCount=", textCount)
  }

  function getFinger(pitch, direction, isChromatic, requestAlternate) {
    var noteClass = pitch % 12 // 0=C 1=C# 2=D 3=d# etc
    var cFinger = "3" // default middle pivot
    var bFinger = "3"
    // c system
    if (noteClass === 0) {
      cFinger = "2" // president rule 2@C
      bFinger = "2"
    } else if (noteClass === 2) {
      cFinger = "3" // D
      bFinger = "4"
    } else if (noteClass === 4) {
      cFinger = "4" // E
      bFinger = "3"
    } else if (noteClass === 5) {
      cFinger = "3" // F
      bFinger = "4"
    } else if (noteClass === 7) {
      cFinger = "4" // G
      bFinger = "3"
    } else if (isChromatic) {
      // use 5-finger technique
      cFinger = (noteClass === 1 || noteClass === 2) ? "1'" : "2'"
      // bFinger = () todo
    } else if (direction === -1) {
      cFinger = "2" // closer-to lower
      bFinger = requestAlternate ? "1" : "2" // closer-to
    } else if (direction === 1) {
      cFinger = "4" // closer-to higher
      bFinger = requestAlternate ? "5" : "4" // closer-to
    }
    return cFinger + "\n" + bFinger
  }
  
  function mapButtonToMidi(row, col) {
    var base = selectedLayout.start
    var off = selectedLayout.offset[col]
    return (base + off) + (row * 3)
  }
  
  function mapMelodicBass(row, col) {
    var stradellaFB = 42 + (row * 5) 
    if (!meloBassMode) { 
      if (col === 5) return stradellaFB + 4
      return stradellaFB
      } else {
        if (col >= 4) {
          return (col === 5) ? (stradellaFB + 4) : stradellaFB
        }
      var base = selectedBassLayout.start
      var off = selectedBassLayout.offset[col]
      var step = selectedBassLayout.vStep
      if (selectedBassLayout.name === "5ths") {
        var targetPitch = (base + off) + (row * step)
        while (targetPitch > 83) targetPitch -= 12
        while (targetPitch < 60) targetPitch += 12
        return targetPitch
      }
      return (base + off) + (row * step)
    }
  }
  
  function isBlackButton(pitch) {
    var p = pitch % 12
    return (p === 1 || p === 3 || p === 6 || p === 8 || p === 10)
  }
  
  function getNoteName(pitch) {
    var names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    return names[pitch % 12]
  }
  
  function identifyChord(pitches) {
    var normalized = []
    for (var i = 0; i < pitches.length; i++) {
      var p = pitches[i] % 12
      if (normalized.indexOf(p) === -1) normalized.push(p)
    }
    var bassNote = (pitches[0] % 12 + 12) % 12
    for (var r = 0; r < normalized.length; r++) {
      var root = normalized[r]
      var mask = 0
      for (var j = 0; j < normalized.length; j++) {
        var interval = (normalized[j] - root + 12) % 12
        mask |= (1 << interval)
      }
      if (chordMap[mask] !== undefined) {
        var suffix = chordMap[mask]
        var chordName = getNoteName(root) + suffix
        if (root !== bassNote) {
          chordName += "/" + getNoteName(bassNote)
        }
        return chordName
      }
    }
    return qsTr("unknown")
  }
  
  function getSelectedPitch() {
    if (!curScore) {
      console.log(qsTr("no score opened"))
      return
    }
    var elements = curScore.selection.elements
    var pitches = []
    for (var i = 0; i < elements.length; i++) {
      if (elements[i].type === Element.NOTE) pitches.push(elements[i].pitch)
    }
    if (pitches.length < 3) {
      foundChordLabel.text = qsTr("select 3+ notes")
      return
    }
    pitches.sort(function(a, b) { return a - b })
    foundChordLabel.text = identifyChord(pitches) 
  }
  
  function addChordText() {
    var chord = foundChordLabel.text
    if (!chord || 
      chord === "none" || 
      chord === "unknown" || 
      chord.indexOf("select") !== -1) return
    var selection = curScore.selection.elements
    if (selection.length === 0) {
      console.log("[addChordText] nothing selected : exiting ...")
      return
    }
    var firstNote = null
    for (var i = 0; i < selection.length; i++) {
      if (selection[i].type === Element.NOTE) { 
        firstNote = selection[i]
        break
      }
    }
    if (!firstNote) {
      console.log("[addChordText] no firstNote : exiting ...")
      return
    }
    console.log("[addChordText] firstNote=" + firstNote)
    console.log("[addChordText] firstNote.track=" + firstNote.track)

    curScore.startCmd()
    var cursor = curScore.newCursor()
    cursor.track = showTreble ? 0 : 4 
    console.log("[addChordText] cursor.track=" + cursor.track)
    cursor.rewind(1) 
    
    if (cursor.segment && cursor.tick !== firstNote.parent.parent.tick) {
      var segment = firstNote.parent.parent
      if (segment) {
        var text = newElement(Element.STAFF_TEXT)
        text.text = chord
        segment.add(text)
        curScore.endCmd()
        return
      }
    }
    
    var textObj = newElement(Element.STAFF_TEXT)
    textObj.text = chord
    if (cursor.segment) {
      cursor.add(textObj)
    }
    curScore.endCmd()
  }
  
  Column { 
    id: mainWidget
    width: parent.width
    height: parent.height
    anchors.fill: parent
    
    Row { 
      id: row1
      height: 30 
      spacing: 4
      anchors.horizontalCenter: parent.horizontalCenter
      Button {
        text: qsTr("get chord")
        ToolTip.text: qsTr("get chord from selected notes - min 3\ncan be added to selected notes")
        ToolTip.visible: hovered
        ToolTip.delay: tooltipDelay 
        onClicked: getSelectedPitch()
      }
      Label {
        id: foundChordLabel
        text: qsTr("none")
        width: 114
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: 18
        minimumPixelSize: 10
        color: highlight1b
        padding: 0
        fontSizeMode: Text.Fit
      }
      Button {
        text: qsTr("add as text")
        ToolTip.text: qsTr("add identified chord to selected notes")
        ToolTip.visible: hovered
        ToolTip.delay: tooltipDelay 
        onClicked: addChordText()
      }
    }
    
    Rectangle {
      id: handleBackground
      width: parent.width
      height: 22 
      color: "#1b1b1b"
      Rectangle {
        id:toggleHandle
        width: 64
        height: 12
        radius: 4
        anchors.centerIn: parent
        color: toggleBtnBrdMouseArea.containsMouse ? highlight1b : "#3c3c3c"
      }
      MouseArea {
        id: toggleBtnBrdMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: showButtonboard = !showButtonboard
      }
    }
    
    Column {
      id:toggleButtonboard
      width: parent.width
      visible: showButtonboard
      height: showButtonboard ? 725 : 0
      spacing: showButtonboard ? 10 : 0
      
      Row { 
        id: row2
        height: 30
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 2
        CheckBox {
          id: meloBassCbx
          text: qsTr("MB") 
          checked: meloBassMode 
          onCheckedChanged: meloBassMode = checked
          ToolTip.text: qsTr("present as melodic / free bass chord vs default stradella bass")
          ToolTip.visible: hovered
          ToolTip.delay: tooltipDelay 
          // added
          indicator: Rectangle {
            implicitWidth: 16
            implicitHeight: 16
            x: 0
            y: parent.height / 2 - height / 2
            radius: 3
            // border.color: "lime"
            color: "white" // highlight1b
            // visible: meloBassCbx.checked
            Rectangle {
              width: 10
              height: 10
              anchors.centerIn: parent
              color: highlight1b
              visible: meloBassCbx.checked
            }
          } 
          // }
          contentItem: Text {
            text: meloBassCbx.text
            // text: parent.text
            color: "white"
            font.pixelSize: 13
            leftPadding: 20
            // leftPadding: textLeftPadding 
            verticalAlignment: Text.AlignVCenter
          }
        }
        CheckBox {
          id: tonesCbx
          text: qsTr("tones")
          ToolTip.text: qsTr("show tone names on buttons")
          ToolTip.visible: hovered
          ToolTip.delay: tooltipDelay 
          checked: showButtonTones
          onCheckedChanged: showButtonTones = checked
          // added
          indicator: Rectangle {
            implicitWidth: 16
            implicitHeight: 16
            x: 0
            y: parent.height / 2 - height / 2
            radius: 3
            // border.color: "lime"
            color: "white" //highlight1b 
            Rectangle {
              width: 10
              height: 10
              anchors.centerIn: parent
              // x: 3
              // y: 3
              radius: 2
              color: highlight1b
              visible: tonesCbx.checked
              }
          }
          contentItem: Text {
            text: tonesCbx.text
            // text: parent.text
            color: "white"
            font.pixelSize: 13
            leftPadding: 20
            // leftPadding: textLeftPadding
            verticalAlignment: Text.AlignVCenter
          }
        } 
        CheckBox {
          id: fingerCbx
          text: qsTr("fingering")
          ToolTip.text: qsTr("add or change fingering to treble part")
          ToolTip.visible: hovered
          ToolTip.delay: tooltipDelay 
          checked: showFingering
          onCheckedChanged: {
            // console.log("dbg : checkbox=", checked)
            showFingering = checked
          }
          // detect double-click
          onClicked: {
            var currentTime = new Date().getTime()
            console.log("dbg : checked=", checked)
            if (checked) {
              // double-click timing
              if (currentTime - lastClickTime < 500) {
                console.log("onClicked : alternate fingering ...")
                calcFinger(true) // request alternate fingering
              } else {
                console.log("onClicked : initial fingering ...")
                calcFinger(false) // initial calculation
              }
            } else {
              console.log("onClicked : hiding fingering")
              hideFinger()
            }
            lastClickTime = currentTime
          }
          // added
          indicator: Rectangle {
            implicitWidth: 16
            implicitHeight: 16
            x:0
            y: parent.height / 2 - height / 2
            radius: 3
            // border.color: "lime"
            color: "white" // highlight1b 
            Rectangle {
              width: 10
              height: 10
              anchors.centerIn: parent
              // x: 3
              // y: 3
              radius: 2
              color: highlight1b
              visible: fingerCbx.checked
            }
          }
          contentItem: Text {
            text: fingerCbx.text
            // text: parent.text
            color: "white"
            font.pixelSize: 13
            leftPadding: 20
            // leftPadding: textLeftPadding
            verticalAlignment: Text.AlignVCenter
          } 
        }
      }
      
      Row { 
        id: row3
        height: 30 // 40
        spacing: 4
        anchors.horizontalCenter: parent.horizontalCenter
        ComboBox { 
          id: bassSelector
          width:comboWidth 
          height: 28 // added
          ToolTip.text: qsTr("select bass layout")
          ToolTip.visible: hovered
          ToolTip.delay: tooltipDelay 
          model: bassLayouts
          textRole: "name"
          onActivated: function(index) { selectedBassLayout = bassLayouts[index] }
          // added
          contentItem: Text {
            text:bassSelector.displayText
            font.pixelSize: 12
            verticalAlignment: Text.AlignVCenter
            leftPadding: 4
            elide: Text.ElideRight
          }
          delegate: ItemDelegate {
            width:bassSelector.width
            height: 25
            contentItem: Text {
              text: modelData.name
              font.pixelSize: 12
              elide: Text.ElideRight
              verticalAlignment: Text.AlignVCenter
            }
          highlighted: bassSelector.highlightedIndex === index
          }
        }
        ComboBox { 
          id: octaveSelector
          width: 52
          height: 28 // added
          ToolTip.text: qsTr("select bass 8ve\n24=5th | .. | 0=3rd | .. | -24=1st\nfor melodic / free bass only")
          ToolTip.visible: hovered
          ToolTip.delay: tooltipDelay 
          model: [24, 12, 0, -12, -24]
          onActivated: function(index) { bassOctaveShift = model[index] }
          // added
          contentItem: Text {
            text: octaveSelector.displayText
            font.pixelSize: 12
            verticalAlignment: Text.AlignVCenter
            leftPadding: 4
          }
          delegate: ItemDelegate {
            width: octaveSelector.width
            height: 25
            contentItem: Text {
              text: modelData
              font.pixelSize: 12
              verticalAlignment: Text.AlignVCenter
            }
            highlighted: octaveSelector.highlightedIndex === index
          }
        }
        ComboBox { 
          id: trebleSelector
          width: comboWidth
          height: 28
          ToolTip.text: qsTr("select treble layout")
          ToolTip.visible: hovered
          ToolTip.delay: tooltipDelay 
          model: layouts
          textRole: "name"
          onActivated: function(index) { selectedLayout = layouts[index] }
          // added
          contentItem: Text {
            text: trebleSelector.displayText
            font.pixelSize: 12
            verticalAlignment: Text.AlignVCenter
            leftPadding: 4
            elide: Text.ElideRight
          }
          delegate: ItemDelegate {
            width: trebleSelector.width
            height: 25
            contentItem: Text {
              text: modelData.name
              font.pixelSize: 12
              elide: Text.ElideRight
              verticalAlignment: Text.AlignVCenter
            }
            highlighted: trebleSelector.highlightedIndex === index
          }
        }
      }
      // buttonboards
      Column { 
        id: boardWidget
        width: parent.width
        spacing: 20
        
        Item {
          id: trebleBrdItem
          width: parent.width
          height: trebleRow.height
          visible: showTreble
          Row {
            id: trebleRow
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: buttonSpacing 
            Repeater {
              model: 5 
              delegate: Column {
                property int colIndex: index
                spacing: buttonSpacing 
                topPadding: (colIndex % 2 === 0) ? 15 : 0 
                Repeater {
                  model: (colIndex % 2 === 0) ? 16 : 17 
                  delegate: Rectangle {
                    width:buttonSize 
                    height: buttonSize
                    radius: buttonSize / 2 
                    property bool isSelected: trebleActivePitches.indexOf(pitch) !== -1
                    property int pitch: mapButtonToMidi(index, colIndex)
                    property bool black: isBlackButton(pitch)
                    color: isSelected ? highlight1b :
                    (black ? "#333333" : "#eeeeee")
                    border.color: "#777777"
                    border.width: 1
                    Text {
                      anchors.centerIn: parent
                      text: !black ? getNoteName(pitch) : ""
                      visible: !black && showButtonTones 
                      font.pixelSize: buttonFontSize
                      color: (black || isSelected) ? "white" : "black"
                    }
                  }
                }
              }
            }
          }
        }
        
        Item { 
          id: bassBrdItem
          width: parent.width
          height: !showTreble ? bassRow.height : 0 
          visible: !showTreble
          Row {
            id: bassRow
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            spacing: bassBtnSpacing
            layoutDirection: Qt.LeftToRight
            Repeater {
              model: ["o", "7", "m", "M", "fb", "cb"]
              delegate: Column {
                id: columnDelegate
                property int col: index
                spacing: bassBtnSpacing
                topPadding: col * (bassBtnSize / 2)
                Repeater {
                  model: 12 
                  delegate: Rectangle {
                    id: rowDelegate
                    property int row: index
                    width: bassBtnSize
                    height: bassBtnSize
                    radius: bassBtnSize / 2
                    property bool isSelected: { 
                      var coordStr = row + "," + columnDelegate.col
                      return bassActivePitches.indexOf(coordStr) !== -1
                      }
                    property int pitch: mapMelodicBass(row, columnDelegate.col)
                    property bool black: isBlackButton(pitch)
                    color: isSelected ? highlight2g : (black ? "#333333" : "#eeeeee")
                    border.color: "#777777"
                    Text {
                      text: {
                        if (columnDelegate.col === 4 || columnDelegate.col === 5) {
                          return getNoteName(pitch)
                        }
                        if (!meloBassMode) {
                          if (rowDelegate.row === 0 || 
                            rowDelegate.row === 6 || 
                            rowDelegate.row === 11) {
                            var chordLabels = ["o", "7", "m", "M"]
                            return chordLabels[columnDelegate.col]
                          }
                          return ""
                        }
                        return getNoteName(pitch)
                      }
                      font.pixelSize: text.length > 1 ? 
                        bassBtnFontSize * 0.68 : 
                        bassBtnFontSize
                      color: (black || isSelected) ? "white" : "black"
                      visible: showButtonTones
                      anchors.centerIn: parent
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
// } 

    // else {
    //   var fbCursor = curScore.newCursor()
    //   fbCursor.rewind(Cursor.SELECTION_START)
    //   if (!fbCursor.segment) {
    //     // console.log("dbg : no active segment at SELECTION_START")
    //     return
    //   }
    //   if (fbCursor.measure) {
    //     startTick = fbCursor.measure.firstSegment.tick
    //     endTick = fbCursor.measure.lastSegment.tick
    //   } else {
    //     // console.log("calcFinger : nothing selected, cant do fingering")
    //   }
    // }
