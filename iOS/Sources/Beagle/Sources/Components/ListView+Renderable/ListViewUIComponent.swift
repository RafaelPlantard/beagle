/*
 * Copyright 2020 ZUP IT SERVICOS EM TECNOLOGIA E INOVACAO SA
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import UIKit
import BeagleSchema

struct ListItemContextResolver {
    
    private var orphanCells = [Int: ListViewCell]()
    private var contexts = [Int: Context]()
    
    mutating func track(orphanCell cell: ListViewCell) {
        if let item = cell.item {
            orphanCells[item] = cell
        }
    }
    
    mutating func reuse(cell: ListViewCell, contextName: String) {
        guard let item = cell.item else { return }
        contexts[item] = cell.itemContext(named: contextName)
        orphanCells.removeValue(forKey: item)
    }
        
    mutating func context(for item: Int, named contextName: String) -> Context? {
        if let orphan = orphanCells[item] {
            reuse(cell: orphan, contextName: contextName)
        }
        return contexts[item]
    }
    
    mutating func reset() {
        while let (_, cell) = orphanCells.popFirst() {
            cell.item = nil
        }
        contexts.removeAll()
    }
    
}

final class ListViewUIComponent: UIView {
    
    // MARK: - Properties
    
    var contextResolver = ListItemContextResolver()
    var renderer: BeagleRenderer
    var model: Model
    var validationSetOnScrollEnd = true
    
    var listViewItems: [DynamicObject]? {
        get { model.listViewItems }
        set {
            model.listViewItems = newValue
            contextResolver.reset()
            collectionView.reloadData()
        }
    }
    
    func verificationOnScrollEnd() {
        let sizeScroll = collectionView.contentSize
        let sizeScreen = self.frame.size
        switch model.direction {
        case .horizontal:
            if sizeScreen.width > sizeScroll.width {
                executeOnScrollEndAction()
                print("sizeScroll: \(sizeScroll.width) // sizeScreen: \(sizeScreen.width)")
            }
        case .vertical :
            if sizeScreen.height > sizeScroll.height {
                executeOnScrollEndAction()
                print("sizeScroll: \(sizeScroll.height) // sizeScreen: \(sizeScreen.height)")
            }
        }
    }
    
    // MARK: - UIComponents
    
    lazy var collectionViewFlowLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = model.direction.scrollDirection
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        return layout
    }()
    
    lazy var collectionView: UICollectionView = {
        let collection = UICollectionView(
            frame: .zero,
            collectionViewLayout: collectionViewFlowLayout
        )
        collection.isScrollEnabled = !model.useParentScroll
        collection.backgroundColor = .clear
        collection.register(ListViewCell.self, forCellWithReuseIdentifier: "ListViewCell")
        collection.translatesAutoresizingMaskIntoConstraints = true
        collection.dataSource = self
        collection.delegate = self
        return collection
    }()
    
    // MARK: - Initialization
    
    init(model: Model, renderer: BeagleRenderer) {
        self.model = model
        self.renderer = renderer
        super.init(frame: .zero)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        addSubview(collectionView)
    }
    
    override func layoutSubviews() {
        collectionView.frame = bounds
        collectionView.reloadData()
        super.layoutSubviews()
    }
    
}

// MARK: - Model
extension ListViewUIComponent {
    struct Model {
        var listViewItems: [DynamicObject]?
        var direction: ListView.Direction
        var template: RawComponent
        var iteratorName: String
        var onScrollEnd: [RawAction]?
        var scrollThreshold: CGFloat
        var useParentScroll: Bool
    }
}

// MARK: UICollectionViewDataSource

extension ListViewUIComponent: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return model.listViewItems?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ListViewCell", for: indexPath)
        if let cell = cell as? ListViewCell {
            contextResolver.reuse(cell: cell, contextName: model.iteratorName)
            cell.configure(item: indexPath.item, listView: self)
        }
        
        return cell
    }
    
}

// MARK: UICollectionViewDelegateFlowLayout

extension ListViewUIComponent: UICollectionViewDelegateFlowLayout {
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        // The value returned here acts as the estimated sized, the frame size
        // is returned to create as few cells as possible.
        // The final size is calculated at ListViewCell.configure(item:listView:)
        // and set at ListViewCell.preferredLayoutAttributesFitting(_:).
        return frame.size
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        didEndDisplaying cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        if let cell = cell as? ListViewCell {
            contextResolver.track(orphanCell: cell)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !validationSetOnScrollEnd else { return }
        
        let sizeKeyPath: KeyPath<CGSize, CGFloat>
        let pointKeyPath: KeyPath<CGPoint, CGFloat>
        switch model.direction {
        case .vertical:
            (sizeKeyPath, pointKeyPath) = (\.height, \.y)
        case .horizontal:
            (sizeKeyPath, pointKeyPath) = (\.width, \.x)
        }
        
        let size = scrollView.contentSize[keyPath: sizeKeyPath]
        let offset = scrollView.contentOffset[keyPath: pointKeyPath] + frame.size[keyPath: sizeKeyPath]
        if size > 0 && offset / size * 100 >= model.scrollThreshold {
            executeOnScrollEndAction()
            validationSetOnScrollEnd = false
        }
    }

    func executeOnScrollEndAction() {
         renderer.controller.execute(actions: model.onScrollEnd, origin: self)
    }
    
}
