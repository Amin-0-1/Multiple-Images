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
    
    var images: [UIImage] = []
    let group = DispatchGroup()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: .add, style: .plain, target: self, action: #selector(addImages))
        navigationItem.leftBarButtonItem = editButtonItem
    }
    
    @objc func addImages(){
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 0
        
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

extension ViewController : PHPickerViewControllerDelegate{
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)
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
        return CGSize(width: (view.frame.width / 2) - 32 , height: 100)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 50, left: 16, bottom: 50, right: 16)
    }
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        setEditing(isEditing, animated: true)
    }
    
}

extension ViewController: ImageCellDelegate{
    func deleteImage(withingCell cell: UICollectionViewCell) {
        
        guard let index = uiCollectionView.indexPath(for: cell) else {return}
        
        images.remove(at: index.item)
        uiCollectionView.deleteItems(at: [index])
    }
}
