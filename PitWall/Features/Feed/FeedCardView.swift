import SwiftUI

/// One feed entry: imagery (or styled placeholder), source, title, caption and
/// relative time. Opens the original post when tapped.
struct FeedCardView: View {
    let item: FeedItem
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            imageSection
                .frame(height: 132)
                .frame(maxWidth: .infinity)
                .clipped()

            VStack(alignment: .leading, spacing: PWSpacing.xs) {
                HStack(spacing: PWSpacing.xs) {
                    TeamColorBar(color: tint, height: 14)
                    Text(item.source)
                        .font(PWTypography.captionBold)
                        .foregroundStyle(PWColors.textPrimary)
                    Text(item.sourceType.displayName.uppercased())
                        .font(PWTypography.microCaps)
                        .kerning(1.0)
                        .foregroundStyle(PWColors.textTertiary)
                    Spacer()
                    Text(PitWallDate.relativeTimeString(from: item.publishedAt))
                        .font(PWTypography.caption)
                        .monospacedDigit()
                        .foregroundStyle(PWColors.textTertiary)
                }

                Text(item.title)
                    .font(PWTypography.cardTitle)
                    .foregroundStyle(PWColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                if let caption = item.caption {
                    Text(caption)
                        .font(PWTypography.caption)
                        .foregroundStyle(PWColors.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(PWSpacing.md)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .pwCardBackground()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.source): \(item.title), \(PitWallDate.relativeTimeString(from: item.publishedAt))")
    }

    @ViewBuilder
    private var imageSection: some View {
        if let imageURL = item.imageURL {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    FeedImagePlaceholder(sourceType: item.sourceType, tint: tint)
                default:
                    ZStack {
                        PWColors.surfaceSunken
                        ProgressView()
                            .tint(PWColors.textTertiary)
                    }
                }
            }
        } else {
            FeedImagePlaceholder(sourceType: item.sourceType, tint: tint)
        }
    }
}

#Preview("FeedCard") {
    let item = MockFeedFactory.makeFeed()[0]
    return FeedCardView(item: item, tint: ColorHex.color("#FF8000"))
        .padding()
        .background(PWColors.background)
}
