//
//  MealReadAndModifyEditViewController.swift
//  DietLog-MVVM
//
//  Created by Jooyeon Kang on 2024/05/01.
//

import UIKit
import RealmSwift
import RxSwift

class MealReadAndModifyEditViewController: MealEditViewController {

    // MARK: - 변수
    private var selectedDate: Date?
    private var mealId: ObjectId?
    private var mealData: Meal?
    private var viewModel = MealEditViewModel()
    private var disposeBag = DisposeBag()
    
    private var isEditable: Bool = false {
        willSet {
            mealEditView.memoTextView.isEditable = newValue
            
            if newValue {
                mealEditView.memoTextView.becomeFirstResponder()
            } else {
                mealEditView.memoTextView.resignFirstResponder()
            }
        }
    }

    // MARK: - 초기화
    init(selectedDate: Date, mealId: ObjectId) {
        super.init(nibName: nil, bundle: nil)
        self.selectedDate = selectedDate
        self.mealId = mealId
    }
    
    // MARK: - Life Cylce
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadMealData()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup NavigationBar
    override func setupNavigationBar() {
        let button = UIBarButtonItem(image: UIImage(named: "OptionMenu"),
                                     style: .plain,
                                     target: self,
                                     action: #selector(openOptionMenu))
        navigationItem.rightBarButtonItem = button
        
        navigationItem.title = "내 식단"
    }
    
    // MARK: - Setup Bind
    override func setupBinding() {
        mealEditView.memoTextView.rx.attributedText
            .bind(to: viewModel.memoTextView)
            .disposed(by: disposeBag)
        
        viewModel.mealData
            .subscribe { [weak self] result in
                self?.mealData = result
            }
            .disposed(by: disposeBag)
    }
    
    private func reloadMealData() {
        if let mealId = mealId {
            viewModel.getMealData(with: mealId)
        }
        
        updateUI()
        
        isEditable = false
    }
    
    private func updateUI() {
        guard let mealData = mealData else { return }
        
        DispatchQueue.main.async {
            self.mealEditView.memoTextView.text = mealData.memo
            let image = self.viewModel.loadImage(with: mealData.imageName)
            self.insertImageIntoTextView(image ?? UIImage())
        }
    }
}

// Modify, Delete
extension MealReadAndModifyEditViewController {
    @objc func openOptionMenu() {
        showOptionMenuSheet(modifyCompletion: {
            self.changeMemoViewEditable()
        }, deleteCompletion: {
            self.deleteMealData()
        })
    }
    
    private func changeMemoViewEditable() {
        let button = UIBarButtonItem(title: "저장",
                                     style: .plain,
                                     target: self,
                                     action: #selector(modifyMealData))
        navigationItem.rightBarButtonItem = button
        
        isEditable = true
    }
    
    @objc func modifyMealData() {
        let image: UIImage? = retrunImage()
        
        guard let mealData = mealData else { return }
        viewModel.modifyMealData(mealData,
                                 selectedDate: selectedDate ?? Date.now,
                                 memo: mealEditView.memoTextView.text,
                                 selectedImage: image)

        showAlertWithOKButton(title: "", message: "수정했습니다") {
            guard let mealId = self.mealId else { return }
            self.viewModel.getMealData(with: mealId)
            self.isEditable = false
        }
    }
    
    private func deleteMealData() {
        guard let mealData = mealData else { return }
        viewModel.deleteMealData(mealData)
        
        showAlertWithOKButton(title: "", message: "삭제했습니다") {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    private func retrunImage() -> UIImage? {
        guard let attributedText = mealEditView.memoTextView.attributedText else { return nil }
        
        let range = NSRange(location: 0, length: attributedText.length)
        
        var image: UIImage?
        
        attributedText.enumerateAttribute(.attachment, in: range) { value, range, pointer in
            if let attachment = value as? NSTextAttachment,
               let selectedImage = attachment.image {
                pointer.pointee = true
                image = selectedImage
            }
        }
        
        return image
    }
}
