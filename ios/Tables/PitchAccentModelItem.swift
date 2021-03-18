// Copyright 2021 David Sansome
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation
import Macaw

class PitchAccentModelItem: UIView {
  let subject: TKMSubject
  let reading: String
  let pitchType: Int

  init(subject: TKMSubject,
       reading: String,
       pitchType: Int,
       top: Double)
  {
    self.subject = subject
    self.reading = reading
    self.pitchType = pitchType

    let screenSize = UIScreen.main.bounds
    let frame = CGRect(x: 0, y: CGFloat(top), width: screenSize.width, height: 50)

    super.init(frame: frame)

    // setup pitch accent rendering
    // let line = Line(x1: 0, y1: 0, x2: Double(screenSize.width), y2: 25)
    //  .stroke(fill: self.pitchType == 1 ? Color.orange : Color.purple, width: 2)
    let group = Group(contents: [
      // line,
    ])

    var points = [CGPoint]()
    var x: Double = 10
    var y: Double = 10

    let color: Color
    let typeText: String

    switch pitchType {
    case 0:
      color = Color(0xD20CA3)
      typeText = "平板 - Heiban"
    case 1:
      color = Color(0x0CD24D)
      typeText = "尾高 - Odaka"
    case 2:
      color = Color(0x27A2FF)
      typeText = "中高 - Nakadaka"
    case 3:
      color = Color(0xEA9316)
      typeText = "頭高 - Atamadaka"
    default:
      color = Color(0x000000)
      typeText = "Unknown"
    }

    if pitchType != -1 {
      for i in 0 ... reading.count + 1 {
        let high = pitchType == 0 ? (i > 0) // heiban
          : pitchType == 1 ? (i == 0) // atamadaka
          : (i > 0 && i < pitchType) // nakadaka/odaka

        points.append(CGPoint(x: x, y: high ? y : y + 30))
        x += 30
      }

      // draw lines
      for p in 0 ..< (points.count - 1) {
        group.contents.append(Line(x1: Double(points[p].x), y1: Double(points[p].y),
                                   x2: Double(points[p + 1].x),
                                   y2: Double(points[p + 1].y))
            .stroke(fill: color, width: 2))
      }

      // draw dots
      for p in 0 ..< points.count {
        let isParticle = p == points.count - 1
        if isParticle {
          group.contents.append(Point(x: Double(points[p].x), y: Double(points[p].y))
            .stroke(fill: Color.white, width: 7, cap: .round))
          group.contents.append(Circle(cx: Double(points[p].x), cy: Double(points[p].y), r: 3)
            .stroke(fill: Color.black, width: 1, cap: .round))
        } else {
          group.contents.append(Point(x: Double(points[p].x), y: Double(points[p].y))
            .stroke(fill: color, width: 7, cap: .round))
        }
      }
    }

    let text = PitchAccentModelItem.newText(typeText, color, .move(dx: x, dy: y + 25))
    text.font = Font(name: "Helvetica", size: 20, weight: "normal")

    group.contents.append(text)

    // let node = Point(x: x, y: y).stroke(fill: Color.black, width: 7, cap: .round)
    // group.contents.append(node)

    let macawView = MacawView(node: group, frame: frame)
    addSubview(macawView)
  }

  fileprivate static func newText(_ text: String, _ color: Color, _ place: Transform,
                                  baseline: Baseline = .bottom) -> Text {
    Text(text: text, fill: color, align: .min, baseline: baseline, place: place)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
