//
//  ViewController.swift
//  MultibleImagesDemo
//
//  Created by Sulfah on 22/10/2021.
//

import UIKit
import PhotosUI

class ViewController: UIViewController {
    
    @IBOutlet weak var uiCollectionView: UICollectionView!
    @IBOutlet var uiImagePreview: UIImageView!
    @IBOutlet weak var uiBlurBackGround: UIVisualEffectView!
    
    var images: [UIImage] = []
    let group = DispatchGroup()
    var configuration: PHPickerConfiguration!
    var indicator:UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNavBarBtnItems()
        configurePicker()
        configureImgePreview()
        configureActivityIndicator()
    }
    
    func configureNavBarBtnItems(){
        let addBtn = UIBarButtonItem(image: .add, style: .plain, target: self, action: #selector(addImages))
        let limitBtn = UIBarButtonItem(systemItem: .compose, primaryAction: nil, menu: createMenue())
        limitBtn.changesSelectionAsPrimaryAction = true
        navigationItem.rightBarButtonItems = [addBtn,limitBtn]
        navigationItem.leftBarButtonItem = editButtonItem
        func createMenue()->UIMenu{
            var actions: [UIAction] = []
            for i in 0...10{
                actions.append(UIAction(title: "\(i+1)", image: UIImage(systemName: "photo.on.rectangle.angled"), handler: { [weak self] action in
                    guard let self = self else {return}
                    guard let limitNumber = Int(action.title) else {return}
                    self.configuration.selectionLimit = limitNumber
                }))
            }
            
            actions.append(UIAction(title: "♾", image: UIImage(systemName: "photo.on.rectangle.angled"), handler: { [weak self] action in
                guard let self = self else {return}
                self.configuration.selectionLimit = 0
            }))
            return UIMenu(title: "limit image selection", image: UIImage(systemName: "photo"), children: actions)
        }
    }
    
    func configurePicker(){
        configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1 // by default
    }
    
    func configureImgePreview(){
        uiBlurBackGround.bounds = self.view.bounds
        uiImagePreview.bounds = CGRect(x: 0, y: 0, width: self.view.bounds.width * 0.7, height: self.view.bounds.height * 0.7)
    }
    
    func configureActivityIndicator(){
        indicator = UIActivityIndicatorView(style: .large)
        indicator.center = view.center
        view.addSubview(indicator)
    }
    
    @objc func addImages(){
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        picker.modalPresentationStyle = .fullScreen
        present(picker, animated: true)
        
    }
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        let indexs = uiCollectionView.indexPathsForVisibleItems
        
        for index in indexs {
            guard let cell = self.uiCollectionView.cellForItem(at: index) as? Cell else {return}
            cell.isEditing = editing
        }
    }
    
}

//MARK: picking images
extension ViewController : PHPickerViewControllerDelegate{
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)

        indicator.startAnimating()
        convertToImages(phpickerResults: results)
    }
    
    func convertToImages(phpickerResults:[PHPickerResult]){
        let itemProviders:[NSItemProvider] = phpickerResults.map(\.itemProvider)
        var iterator : IndexingIterator<[NSItemProvider]> = itemProviders.makeIterator()
        
        while let itemProvider = iterator.next(),itemProvider.canLoadObject(ofClass: UIImage.self){
            group.enter()
            itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                guard let self = self else {return}
                
                guard let image = image as? UIImage, error == nil else {
                    self.group.leave()
                    return
                    
                }
                self.images.append(image)
                self.group.leave()
            }
        }
        group.notify(queue: .main) { [weak self] in
            guard let self = self else {return}
            self.indicator.stopAnimating()
            self.uiCollectionView.reloadData()
        }
    }
    
    
}

extension ViewController: UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? Cell else {return UICollectionViewCell()}
        
        cell.imageCellDelegate = self
        cell.image.image = images[indexPath.item]
        cell.image.layer.cornerRadius = 24
        cell.image.contentMode = .scaleAspectFill
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (view.frame.width / 2) - 16 , height: 100)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 50, left: 8, bottom: 50, right: 8)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        setEditing(isEditing, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onPreviewImage(forIndexpath: indexPath)
    }
    func onPreviewImage(forIndexpath indexPath:IndexPath){
        uiImagePreview.image = images[indexPath.item]
        uiImagePreview.contentMode = .scaleAspectFit
        animateOut(desiredView: uiBlurBackGround)
        animateOut(desiredView: uiImagePreview)
    }
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        
        func makeRemoveAction(forCell cell:UICollectionViewCell)->UIMenuElement{
            let attr = UIMenuElement.Attributes.destructive
            let image = UIImage(systemName: "delete.left")
            
            return UIAction(title: "Remove", image: image, identifier: nil,attributes: attr) { _ in
                self.deleteImage(withingCell: cell)
            }
        }
        func makePreviewAction(forIndexPath index: IndexPath)-> UIMenuElement{
            let image = UIImage(systemName: "rectangle.portrait.on.rectangle.portrait.fill")
            return UIAction(title: "Preview", image: image) {[unowned self] _ in
                self.onPreviewImage(forIndexpath: index)
            }
        }
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let cell = collectionView.cellForItem(at: indexPath) as! Cell
            
            let remove = makeRemoveAction(forCell: cell)
            let preview = makePreviewAction(forIndexPath: indexPath)
            return UIMenu(title: "",children: [remove,preview])
        }
    }
    
}

//MARK: delegate
extension ViewController: ImageCellDelegate{
    func deleteImage(withingCell cell: UICollectionViewCell) {
        
        guard let index = uiCollectionView.indexPath(for: cell) else {return}
        
        images.remove(at: index.item)
        uiCollectionView.deleteItems(at: [index])
    }
}

//MARK: Preview animations
extension ViewController{
    func animateOut(desiredView: UIView){
        view.addSubview(desiredView)
        desiredView.transform = CGAffineTransform(scaleX: 0, y: 0)
        desiredView.alpha = 0
        
        desiredView.center = view.center
        
        UIView.animate(withDuration: 0.3) {
            if desiredView .isKind(of: UIImage.self){
                desiredView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
            }else{
                desiredView.transform = CGAffineTransform(scaleX: 1, y: 1)
            }
            desiredView.alpha = 1
        }
        desiredView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cancelPreviewSelector)))
    }
    @objc func cancelPreviewSelector(){
        animateIn(desiredView: uiImagePreview)
        animateIn(desiredView: uiBlurBackGround)
    }
    func animateIn(desiredView: UIView){
        UIView.animate(withDuration: 0.3) {
            desiredView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            desiredView.alpha = 0
        } completion: { _ in
            desiredView.removeFromSuperview()
        }
        
    }
}
