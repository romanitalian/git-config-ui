import SwiftUI

enum ProfileTableLayout {
    static let spacing: CGFloat = 10
    static let activeWidth: CGFloat = 44
    /// Edit + Delete hit targets with spacing between them.
    static let actionsWidth: CGFloat = actionHitSize * 2 + actionSpacing
    static let actionHitSize: CGFloat = 28
    static let actionSpacing: CGFloat = 8
    static let rowInsets = EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12)

    /// Shared column grid so data rows stay aligned.
    /// Text columns use flex ≈ 0.9 : 1.1 : 1.4 (Name : Email : Repository).
    static func columns<Active: View, Name: View, Email: View, Repo: View, Actions: View>(
        @ViewBuilder active: () -> Active,
        @ViewBuilder name: () -> Name,
        @ViewBuilder email: () -> Email,
        @ViewBuilder repository: () -> Repo,
        @ViewBuilder actions: () -> Actions
    ) -> some View {
        FlexColumns(spacing: spacing, activeWidth: activeWidth, actionsWidth: actionsWidth) {
            active()
                .debugBorder(UIDebug.global)
            name()
                .debugBorder(UIDebug.name)
            email()
                .debugBorder(UIDebug.email)
            repository()
                .debugBorder(UIDebug.repository)
            actions()
                .debugBorder(UIDebug.actions)
        }
    }
}

/// Five-column row: fixed Active | Name×0.9 | Email×1.1 | Repository×1.4 | fixed Actions.
private struct FlexColumns: Layout {
    var spacing: CGFloat
    var activeWidth: CGFloat
    var actionsWidth: CGFloat

    private let nameFlex: CGFloat = 0.9
    private let emailFlex: CGFloat = 1.1
    private let repositoryFlex: CGFloat = 1.4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let height = subviews.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
        let width = proposal.width ?? (
            activeWidth + actionsWidth + spacing * 4
            + subviews.dropFirst().dropLast().reduce(0) { $0 + $1.sizeThatFits(.unspecified).width }
        )
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard subviews.count == 5 else { return }

        let flexTotal = nameFlex + emailFlex + repositoryFlex
        let gaps = spacing * 4
        let textBudget = max(0, bounds.width - activeWidth - actionsWidth - gaps)
        let nameW = textBudget * nameFlex / flexTotal
        let emailW = textBudget * emailFlex / flexTotal
        let repoW = textBudget * repositoryFlex / flexTotal
        let heights = subviews.map { $0.sizeThatFits(.unspecified).height }
        let maxH = heights.max() ?? bounds.height

        var x = bounds.minX
        let widths = [activeWidth, nameW, emailW, repoW, actionsWidth]
        for i in 0..<5 {
            let w = widths[i]
            let y = bounds.minY + (maxH - heights[i]) / 2
            subviews[i].place(
                at: CGPoint(x: x, y: y),
                proposal: ProposedViewSize(width: w, height: heights[i])
            )
            x += w + spacing
        }
    }
}
