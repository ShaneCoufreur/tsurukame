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

extension UIControl {
  /** You MUST take a weak reference to `self` in the closure. */
  func addAction(for controlEvents: UIControl.Event = .touchUpInside,
                 _ closure: @escaping () -> Void) {
    if #available(iOS 14.0, *) {
      addAction(UIAction { (_: UIAction) in closure() }, for: controlEvents)
    } else {
      @objc class ClosureWrapper: NSObject {
        let closure: () -> Void
        init(_ closure: @escaping () -> Void) { self.closure = closure }
        @objc func invoke() { closure() }
      }

      let wrapper = ClosureWrapper(closure)
      addTarget(wrapper, action: #selector(ClosureWrapper.invoke), for: controlEvents)
      objc_setAssociatedObject(self, "\(UUID())", wrapper,
                               objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }
  }
}
