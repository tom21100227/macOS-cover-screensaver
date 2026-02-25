import ScreenSaver
import os.log

private let log = OSLog(subsystem: "com.tomtopia.screensaver", category: "TomtopiaSaver")

class TomtopiaSaverView: ScreenSaverView {

    private var images: [CGImage] = []
    private var hasBuiltGrid = false
    private let gap: CGFloat = 3

    // MARK: - Init

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        os_log("init frame=%{public}@ isPreview=%{public}d", log: log, type: .debug, NSStringFromRect(frame), isPreview)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        os_log("init from coder", log: log, type: .debug)
        commonInit()
    }

    private func commonInit() {
        animationTimeInterval = 60.0
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
        layer?.masksToBounds = true
        loadImages()
    }

    // MARK: - Image Loading

    private func loadImages() {
        let bundle = Bundle(for: type(of: self))
        os_log("Bundle path: %{public}@", log: log, type: .debug, bundle.bundlePath)

        guard let coversURL = bundle.url(forResource: "covers", withExtension: nil, subdirectory: "Resources") ??
              bundle.url(forResource: "covers", withExtension: nil) else {
            os_log("ERROR: covers directory not found in bundle", log: log, type: .error)
            return
        }

        os_log("Covers URL: %{public}@", log: log, type: .debug, coversURL.path)

        guard let files = try? FileManager.default.contentsOfDirectory(at: coversURL, includingPropertiesForKeys: nil)
            .filter({ $0.pathExtension == "jpg" }) else {
            os_log("ERROR: could not list covers directory", log: log, type: .error)
            return
        }

        for file in files {
            if let img = NSImage(contentsOf: file),
               let cgImg = img.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                images.append(cgImg)
            } else {
                os_log("WARNING: skipped %{public}@", log: log, type: .debug, file.lastPathComponent)
            }
        }

        os_log("Loaded %{public}d cover images", log: log, type: .debug, images.count)
    }

    // MARK: - Grid Building

    override func startAnimation() {
        super.startAnimation()
        os_log("startAnimation bounds=%{public}@ hasBuiltGrid=%{public}d imageCount=%{public}d", log: log, type: .debug, NSStringFromRect(bounds), hasBuiltGrid, images.count)

        // Revalidate: if hasBuiltGrid but no row sublayers exist, force rebuild
        if hasBuiltGrid {
            let rowCount = layer?.sublayers?.filter({ !($0 is CAGradientLayer) }).count ?? 0
            if rowCount == 0 { hasBuiltGrid = false }
        }

        if !hasBuiltGrid && !images.isEmpty && bounds.width > 0 {
            hasBuiltGrid = buildGrid()
        }
    }

    override func stopAnimation() {
        super.stopAnimation()
        os_log("stopAnimation", log: log, type: .debug)
    }

    override func resize(withOldSuperviewSize oldSize: NSSize) {
        super.resize(withOldSuperviewSize: oldSize)
        hasBuiltGrid = false
        layer?.sublayers?.forEach { $0.removeFromSuperlayer() }
        if !images.isEmpty && bounds.width > 0 {
            hasBuiltGrid = buildGrid()
        }
    }

    @discardableResult
    private func buildGrid() -> Bool {
        guard let rootLayer = layer else {
            os_log("buildGrid: layer is nil!", log: log, type: .error)
            return false
        }
        os_log("buildGrid: bounds=%{public}@ sublayers=%{public}d", log: log, type: .debug, NSStringFromRect(bounds), rootLayer.sublayers?.count ?? 0)

        let vw = bounds.width
        let vh = bounds.height

        let coversPerRow: Int
        if vw >= 1024 {
            coversPerRow = 8
        } else if vw >= 640 {
            coversPerRow = 5
        } else {
            coversPerRow = 3
        }

        let coverSize = ceil(vw / CGFloat(coversPerRow))
        let rowCount = Int(ceil(vh / coverSize)) + 1
        let setCount = coversPerRow + 1
        let setWidthPx = (coverSize + gap) * CGFloat(setCount)
        let staggerPx = floor(coverSize / 2)

        let shuffled = images.shuffled()

        let cx = vw / 2
        let cy = vh / 2

        for i in 0..<rowCount {
            let rowLayer = CALayer()
            // macOS uses bottom-left origin; place rows from top
            let rowY = vh - CGFloat(i + 1) * (coverSize + gap)
            rowLayer.frame = CGRect(x: 0, y: rowY, width: vw, height: coverSize)
            rowLayer.masksToBounds = false

            let isRightRow = i % 2 == 1

            // Build 4× repeated set of covers
            var rowImages: [CGImage] = []
            for j in 0..<setCount {
                let idx = ((i * 7 + j) % shuffled.count + shuffled.count) % shuffled.count
                rowImages.append(shuffled[idx])
            }
            let fullRow = rowImages + rowImages + rowImages + rowImages

            let rowScrollOffset: CGFloat = isRightRow
                ? CGFloat(setCount) * (coverSize + gap) + staggerPx
                : 0

            for j in 0..<fullRow.count {
                let img = fullRow[j]

                let coverLayer = CALayer()
                let x = CGFloat(j) * (coverSize + gap)
                coverLayer.frame = CGRect(x: x, y: 0, width: coverSize, height: coverSize)
                coverLayer.contents = img
                coverLayer.contentsGravity = .resizeAspectFill
                coverLayer.masksToBounds = true

                // Fly-in: calculate offset from center
                let coverX = x + coverSize / 2 - rowScrollOffset
                let coverY = CGFloat(i) * (coverSize + gap) + coverSize / 2

                var flyX: CGFloat = 0
                var flyY: CGFloat = 0
                let rangeLimit = CGFloat(setCount) * (coverSize + gap)
                if coverX >= -rangeLimit && coverX <= vw + rangeLimit {
                    flyX = (coverX - cx) * 1.5
                    // Invert Y because macOS coordinate system is flipped vs CSS
                    flyY = -((coverY - cy) * 1.5)
                }

                let flyDelay = Double.random(in: 0...1)

                // Model layer at FINAL state (prevents snap-back if animation is removed)
                let startTransform = CATransform3DConcat(
                    CATransform3DMakeTranslation(flyX, flyY, 0),
                    CATransform3DMakeScale(1.8, 1.8, 1)
                )
                coverLayer.opacity = 1
                coverLayer.transform = CATransform3DIdentity

                // Fly-in: animate FROM start state TO final (model layer) state
                let moveAnim = CABasicAnimation(keyPath: "transform")
                moveAnim.fromValue = startTransform
                moveAnim.duration = 1.0
                moveAnim.timingFunction = CAMediaTimingFunction(controlPoints: 0.22, 1.0, 0.36, 1.0)

                let fadeAnim = CABasicAnimation(keyPath: "opacity")
                fadeAnim.fromValue = 0.0
                fadeAnim.duration = 0.4
                fadeAnim.timingFunction = CAMediaTimingFunction(name: .easeOut)

                let group = CAAnimationGroup()
                group.animations = [moveAnim, fadeAnim]
                group.beginTime = CACurrentMediaTime() + flyDelay
                group.duration = 1.0
                group.fillMode = .backwards
                group.isRemovedOnCompletion = true

                coverLayer.add(group, forKey: "flyIn")

                rowLayer.addSublayer(coverLayer)
            }

            rootLayer.addSublayer(rowLayer)

            // Scroll animation for the row
            let scrollDistance = setWidthPx
            let scrollAnim = CABasicAnimation(keyPath: "position.x")

            if isRightRow {
                // Scroll right: start offset left, move to base position
                let baseX = rowLayer.position.x
                scrollAnim.fromValue = baseX - scrollDistance - staggerPx
                scrollAnim.toValue = baseX - staggerPx
            } else {
                // Scroll left: start at base, move left by one set width
                let baseX = rowLayer.position.x
                scrollAnim.fromValue = baseX
                scrollAnim.toValue = baseX - scrollDistance
            }

            scrollAnim.duration = 120
            scrollAnim.repeatCount = .infinity
            scrollAnim.timingFunction = CAMediaTimingFunction(name: .linear)

            rowLayer.add(scrollAnim, forKey: "scroll")
        }

        // Vignette overlay
        let vignette = CAGradientLayer()
        vignette.frame = CGRect(x: 0, y: 0, width: vw, height: vh)
        vignette.type = .radial
        vignette.colors = [
            NSColor(white: 0, alpha: 0).cgColor,
            NSColor(white: 0, alpha: 0).cgColor,
            NSColor(white: 0, alpha: 0.15).cgColor,
            NSColor(white: 0, alpha: 0.35).cgColor,
        ]
        vignette.locations = [0, 0.4, 0.7, 1.0]
        vignette.startPoint = CGPoint(x: 0.5, y: 0.5)
        vignette.endPoint = CGPoint(x: 1, y: 1)
        vignette.zPosition = 100

        rootLayer.addSublayer(vignette)

        return true
    }

    // MARK: - ScreenSaverView overrides

    override func animateOneFrame() {
        // Core Animation handles all animation
    }

    override var hasConfigureSheet: Bool { false }
    override var configureSheet: NSWindow? { nil }

    deinit {
        func removeAnimationsRecursively(_ layer: CALayer) {
            layer.removeAllAnimations()
            layer.sublayers?.forEach { removeAnimationsRecursively($0) }
        }
        if let root = layer { removeAnimationsRecursively(root) }
    }
}
