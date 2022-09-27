//
//  SecondModel.swift
//  GyroData
//
//  Created by pablo.jee on 2022/09/20.
//
//TODO: 특정 시점에서 graphViewModel이 didReceiveData, didReceiveAll 호출하게끔 추가

import Foundation
import CoreMotion
import UIKit

class SecondModel {
    // MARK: Input
    var didTapBackButton: () -> () = { }
    var didTapSaveButton: () -> () = { }
    
    // MARK: Output
    var routeSubject: (SceneCategory) -> () = { sceneCategory in }
    var motionMeasuresSource: ([MotionMeasure]) -> () = { measures in } {
        didSet {
            motionMeasuresSource(_motionMeasures)
        }
    }
    var isMeasuringSource: (Bool) -> () = { isMeasuring in } {
        didSet {
            isMeasuringSource(_isMeasuring)
        }
    }
    var isLoadingSource: (Bool) -> () = { isLoading in } {
        didSet {
            isLoadingSource(_isLoading)
        }
    }
    
    // MARK: Properties
    private var repository: RepositoryProtocol
    private var motionManager: CoreMotionManagerProtocol
    var segmentViewModel: SecondSegmentViewModel
    var controlViewModel: SecondControlViewModel
    var graphViewModel: GraphViewModel
    
    private var _motionMeasures = [MotionMeasure]() {
        didSet {
            graphViewModel.didReceiveData(_motionMeasures)
            motionMeasuresSource(_motionMeasures)
        }
    }
    private var _isMeasuring: Bool = false {
        didSet {
            isMeasuringSource(_isMeasuring)
            segmentViewModel.didReceiveIsMeasuring(_isMeasuring)
            controlViewModel.didReceiveIsMeasuring(_isMeasuring)
        }
    }
    private var _isLoading: Bool = false {
        didSet {
            isLoadingSource(_isLoading)
        }
    }
    
    // MARK: Init
    init(repository: RepositoryProtocol, motionManager: CoreMotionManagerProtocol) {
        self.repository = repository
        self.motionManager = motionManager
        self.segmentViewModel = SecondSegmentViewModel()
        self.controlViewModel = SecondControlViewModel()
        self.graphViewModel = GraphViewModel()
        bind()
    }
    
    // MARK: Bind
    func bind() {
        didTapBackButton = { [weak self] in
            self?.routeSubject(.close)
        }
        
        didTapSaveButton = { [weak self] in
            guard let self else { return }
            if self._isMeasuring {
                debugPrint("측정 중에는 저장할 수 없습니다.")
                return
            }
            if self._motionMeasures.isEmpty {
                let okAction = AlertActionDependency(title: "확인")
                let alertDependancy = AlertDependency(title: nil, message: "측정된 데이터가 없습니다.", preferredStyle: .alert, actionSet: [okAction])
                self.routeSubject(.alert(alertDependancy))
                return
            }
            Task {
                await self.saveMotionMeasures()
            }
        }
        
        controlViewModel.propagateDidTapMeasureButton = { [weak self] in
            guard let self else { return }
            let type = self.segmentViewModel.selectedType
            do {
                self._motionMeasures = []
                try self.motionManager.startUpdate(type)
                self._isMeasuring = true
            } catch let error {
                debugPrint(error)
            }
        }
        
        controlViewModel.propagateDidTapStopButton = { [weak self] in
            guard let self else { return }
            let type = self.segmentViewModel.selectedType
            self.motionManager.stopUpdate(type)
            self._isMeasuring = false
        }
        
        motionManager.gyroHandler = { [weak self] data, error in
            guard
                error == nil,
                let data,
                let self
            else { return }
            self._motionMeasures.append(MotionMeasure(data))
            debugPrint(MotionMeasure(data))
        }
        
        motionManager.accHandler = { [weak self] data, error in
            guard
                error == nil,
                let data,
                let self
            else { return }
            self._motionMeasures.append(MotionMeasure(data))
            debugPrint(MotionMeasure(data))
        }
    }
    
    @MainActor
    func saveMotionMeasures() async {
        do {
            self._isLoading = true
            // TODO: FileManager 저장 로직을 넣고, 그 값을 path에 넣어야합니다.
            let motionTask = MotionTask(
                type: segmentViewModel.selectedType.rawValue,
                time: Float(_motionMeasures.count) * 0.1,
                date: Date(),
                path: "")
            _ = try await self.repository.insertToCoreData(motion: motionTask)
            self._isLoading = false
            let okAction = AlertActionDependency(title: "확인") { _ in
                let context = SceneContext(dependency: FirstSceneAction.refresh)
                self.routeSubject(.closeWithAction(.main(.firstViewControllerWithAction(context: context))))
            }
            let alertDependancy = AlertDependency(title: nil, message: "저장이 완료되었습니다.", preferredStyle: .alert, actionSet: [okAction])
            self.routeSubject(.alert(alertDependancy))
        } catch let error {
            self._isLoading = false
            let okAction = AlertActionDependency(title: "확인")
            let alertDependancy = AlertDependency(title: nil, message: error.localizedDescription, preferredStyle: .alert, actionSet: [okAction])
            self.routeSubject(.alert(alertDependancy))
        }
    }
}
