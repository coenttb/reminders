public import CasePaths
import Interface_ComposableArchitecture
public import Operation
public import Reminders

// A Call used as a feature's Action is CasePathable through its own optics (see CallPaths).
extension Reminders.Call: CasePathable {}
extension Reminders.Lists.Create.Call: CasePathable {}
