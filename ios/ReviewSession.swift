// Copyright 2025 David Sansome
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
import WaniKaniAPI

class ReviewSession {
  private let services: TKMServices

  private var activeQueue = [ReviewItem]()
  private var reviewQueue = [ReviewItem]()
  public private(set) var completedReviews = [ReviewItem]()
  private var activeQueueSize = 1

  private var isPracticeSession = false

  private var activeTaskIndex = 0 // An index into activeQueue.
  public private(set) var activeTaskType: TaskType!
  public private(set) var activeTask: ReviewItem!
  public private(set) var activeSubject: TKMSubject!
  public private(set) var activeStudyMaterials: TKMStudyMaterials?

  public private(set) var tasksAnsweredCorrectly = 0
  public private(set) var tasksAnswered = 0
  public private(set) var reviewsCompleted = 0

  public var wrappingUp: Bool = false

  init(services: TKMServices, items: [ReviewItem], isPracticeSession: Bool = false) {
    self.services = services
    reviewQueue = items
    self.isPracticeSession = isPracticeSession

    if Settings.groupMeaningReading || (Settings.ankiMode &&
      Settings.ankiModeCombineReadingMeaning) || self.isPracticeSession {
      activeQueueSize = 1
    } else {
      activeQueueSize = Int(Settings.reviewBatchSize)
    }

    refillActiveQueue()
  }

  public var activeQueueLength: Int {
    activeQueue.count
  }

  public var reviewQueueLength: Int {
    reviewQueue.count
  }

  public var successRateText: String {
    if tasksAnswered == 0 {
      return "100%"
    }
    return String(Int(Double(tasksAnsweredCorrectly) / Double(tasksAnswered) * 100)) + "%"
  }

  public var hasStarted: Bool {
    activeTask != nil
  }

  public var activeAssignment: TKMAssignment! {
    activeTask.assignment
  }

  public func nextTask() {
    guard !activeQueue.isEmpty else {
      return
    }

    activeTaskIndex = Int(arc4random_uniform(UInt32(activeQueue.count)))
    activeTask = activeQueue[activeTaskIndex]

    if let subject = activeTask.subject {
      activeSubject = subject
      activeStudyMaterials = nil
    } else {
      activeSubject = services.localCachingClient.getSubject(id: activeTask.assignment.subjectID)!
      activeStudyMaterials =
        services.localCachingClient.getStudyMaterial(subjectId: activeTask.assignment.subjectID)
    }

    // Choose whether to ask the meaning or the reading.
    if activeTask.answeredMeaning || activeSubject.meanings.isEmpty {
      activeTaskType = .reading
    } else if activeTask.answeredReading || activeSubject.readings.isEmpty {
      activeTaskType = .meaning
    } else if Settings.groupMeaningReading || (Settings.ankiMode &&
      Settings.ankiModeCombineReadingMeaning) || isPracticeSession {
      activeTaskType = Settings.meaningFirst ? .meaning : .reading
    } else {
      activeTaskType = TaskType.random()
    }
  }

  public func moveActiveTaskToEnd() {
    activeQueue.remove(at: activeTaskIndex)
    activeTask.reset()
    reviewQueue.append(activeTask)
    refillActiveQueue()
  }

  public func excludeTask() {
    activeQueue.remove(at: activeTaskIndex)
    activeTask.reset()
    refillActiveQueue()
  }

  struct MarkResult {
    let subjectFinished: Bool
    let didLevelUp: Bool
    let newSrsStage: SRSStage
  }

  private var lastMarkAnswerWasFirstTime = false
  public func markAnswer(_ result: AnswerResult,
                         isPracticeSession: Bool = false) -> MarkResult {
    var firstTimeAnswered = false
    switch activeTaskType {
    case .meaning:
      firstTimeAnswered = !activeTask.answer.hasMeaningWrong
      if firstTimeAnswered ||
        (lastMarkAnswerWasFirstTime && result == .OverrideAnswerCorrect) {
        activeTask.answer.meaningWrong = !result.correct
        if result == .OverrideAnswerCorrect {
          activeTask.answer.meaningWrongCount -= 1
        }
      }
      activeTask.answeredMeaning = result.correct

      if !result.correct {
        activeTask.answer.meaningWrongCount += 1
      }

    case .reading:
      firstTimeAnswered = !activeTask.answer.hasReadingWrong
      if firstTimeAnswered ||
        (lastMarkAnswerWasFirstTime && result == .OverrideAnswerCorrect) {
        activeTask.answer.readingWrong = !result.correct
        if result == .OverrideAnswerCorrect {
          activeTask.answer.readingWrongCount -= 1
        }
      }
      activeTask.answeredReading = result.correct

      if !result.correct {
        activeTask.answer.readingWrongCount += 1
      }

    default:
      fatalError()
    }
    lastMarkAnswerWasFirstTime = firstTimeAnswered

    // Update stats.
    switch result {
    case .Correct:
      tasksAnswered += 1
      tasksAnsweredCorrectly += 1

    case .Incorrect:
      tasksAnswered += 1

    case .OverrideAnswerCorrect:
      tasksAnsweredCorrectly += 1

    case .Exclude:
      fatalError()
    case .AskAgainLater:
      // Handled above.
      fatalError()
    }

    // Remove it from the active queue if that was the last part.
    let shouldIgnoreReading: Bool = activeSubject.hasKanji && Settings.skipKanjiReadings
    let answeredReading: Bool = activeTask.answeredReading || activeSubject
      .readings.isEmpty
    let isSubjectFinished =
      (activeTask.answeredMeaning || activeSubject.meanings.isEmpty) &&
      (shouldIgnoreReading || answeredReading)
    let didLevelUp = (!activeTask.answer.readingWrong && !activeTask.answer
      .meaningWrong && !isPracticeSession)
    let newSrsStage =
      didLevelUp ? activeAssignment.srsStage.next : activeAssignment.srsStage
        .previous
    if isSubjectFinished {
      let date = Int32(Date().timeIntervalSince1970)
      if date > activeAssignment.availableAt {
        activeTask.answer.createdAt = date
      }

      if Settings.minimizeReviewPenalty {
        if activeTask.answer.meaningWrong {
          activeTask.answer.meaningWrongCount = 1
        }
        if activeTask.answer.readingWrong {
          activeTask.answer.readingWrongCount = 1
        }
      }

      if !isPracticeSession {
        _ = services.localCachingClient!.sendProgress([activeTask.answer])
      }

      reviewsCompleted += 1
      completedReviews.append(activeTask)
      activeQueue.remove(at: activeTaskIndex)
      refillActiveQueue()
    }

    return MarkResult(subjectFinished: isSubjectFinished, didLevelUp: didLevelUp,
                      newSrsStage: newSrsStage)
  }

  func addSynonym(_ text: String) {
    if activeStudyMaterials == nil {
      activeStudyMaterials = TKMStudyMaterials()
      activeStudyMaterials!.subjectID = activeSubject.id
    }
    activeStudyMaterials!.meaningSynonyms.append(text)
    _ = services.localCachingClient?.updateStudyMaterial(activeStudyMaterials!)
  }

  func setExclude(_ exclude: Bool) {
    if activeStudyMaterials == nil {
      activeStudyMaterials = TKMStudyMaterials()
      activeStudyMaterials!.subjectID = activeSubject.id
    }
    _ = services.localCachingClient?.setExcluded(studyMaterials: &activeStudyMaterials!,
                                                 shouldExclude: exclude)
  }

  private func refillActiveQueue() {
    if wrappingUp {
      return
    }

    while activeQueue.count < activeQueueSize, reviewQueue.count != 0 {
      let item = reviewQueue.first!
      reviewQueue.removeFirst()
      activeQueue.append(item)
    }
  }
}
