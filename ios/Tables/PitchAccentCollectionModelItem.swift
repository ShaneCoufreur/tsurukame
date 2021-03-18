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

class PitchAccentCollectionModelItem: NSObject, TKMModelItem {
  // let subjects: [Int32]
  let localCachingClient: LocalCachingClient
  // weak var delegate: SubjectChipDelegate?
  let subject: TKMSubject

  /* init(subjects: [Int32], localCachingClient: LocalCachingClient,
   delegate: SubjectChipDelegate) { */
  init(subject: TKMSubject,
       localCachingClient: LocalCachingClient) {
    self.subject = subject
    self.localCachingClient = localCachingClient
    // self.subjects = subjects
    // self.localCachingClient = localCachingClient
    // self.delegate = delegate
  }

  func cellClass() -> AnyClass! {
    PitchAccentCollectionModelView.self
  }
}

private class PitchAccentCollectionModelView: TKMModelCell {
  // var chips = [SubjectChip]()
  var pitchAccents = [UIView]()

  override func update(with item: TKMModelItem!) {
    super.update(with: item)
    guard let item = item as? PitchAccentCollectionModelItem else {
      return
    }

    for pitchAccent in pitchAccents {
      pitchAccent.removeFromSuperview()
    }
    pitchAccents.removeAll()

    // let pitchaccentType = vocabPitchAccent[item.subject.japanese]

    var accents = item.localCachingClient.getPitchAccent(japanese: item.subject.japanese)

    var top = 0.0
    if accents.count == 0 {
      accents.append(-1)
    }

    for pa in accents {
      let pitchAccentModelItem = PitchAccentModelItem(subject: item.subject,
                                                      reading: item.subject.readings[0].reading,
                                                      pitchType: pa,
                                                      top: top)
      contentView.addSubview(pitchAccentModelItem)
      pitchAccents.append(pitchAccentModelItem)
      top += 25
    }

    /* selectionStyle = .none
     top
     // Remove all existing chips.
     for chip in chips {
       chip.removeFromSuperview()
     }
     chips.removeAll()

     // Create a chip for each subject.
     for subjectId in item.subjects {
       if let subject = item.localCachingClient.getSubject(id: subjectId),
         let delegate = item.delegate {
         let chip = SubjectChip(subject: subject, showMeaning: true, delegate: delegate)
         contentView.addSubview(chip)
         chips.append(chip)
       }
     }
     setNeedsLayout() */
  }

  /* override func layoutSubviews() {
     super.layoutSubviews()

     let frames = calculateSubjectChipFrames(chips: chips, width: frame.size.width, alignment: .left)
     for (idx, frame) in frames.enumerated() {
       chips[idx].frame = frame
     }
   } */

  override func sizeThatFits(_ size: CGSize) -> CGSize {
    /* if chips.isEmpty {
       return size
     }
     let frames = calculateSubjectChipFrames(chips: chips, width: frame.size.width, alignment: .left)
     if frames.isEmpty {
       return size
     }
     return CGSize(width: size.width,
                   height: frames.last!.maxY +
                     kSubjectChipCollectionEdgeInsets.bottom) */

    CGSize(width: size.width,
           height: CGFloat(pitchAccents.count * 50))
  }
}
