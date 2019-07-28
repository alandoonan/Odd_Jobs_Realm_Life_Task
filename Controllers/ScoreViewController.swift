//
//  ScoreViewController.swift
//  Odd_Jobs_Realm
//
//  Created by Alan Doonan on 15/07/2019.
//  Copyright © 2019 Alan Doonan. All rights reserved.
//

import UIKit
import RealmSwift
import RSSelectionMenu

class ScoreViewController: UIViewController {
    
    //Realm Items
    let realm: Realm
    var items: Results<ScoreItem>
    var sorts : Results<ScoreItem>!
    var shapeLayer: CAShapeLayer!
    var pulsatingLayer: CAShapeLayer!
    let scoreLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 32)
        label.textColor = .white
        return label
    }()
    let userLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 32)
        label.textColor = .white
        return label
    }()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @objc private func handleEnterForeground() {
        animatePulsatingLayer()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        let config = SyncUser.current?.configuration(realmURL: Constants.ODDJOBS_REALM_URL, fullSynchronization: true)
        self.realm = try! Realm(configuration: config!)
        self.items = realm.objects(ScoreItem.self).filter("Category contains[c] %@", "Score")
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //Score System Checks
    fileprivate func checkingScoreSystem() {
        if let scoreItem = realm.objects(ScoreItem.self).first
        {
            print("There is a score object")
            print(realm.objects(ScoreItem.self).count)
            print (scoreItem.Category)
        } else {
            print("No first object!")
            print("Creating scoring object")
            let scoreItem = ScoreItem()
            scoreItem.Name = "Total Score"
            scoreItem.Score = 0
            try! self.realm.write {
                self.realm.add(scoreItem)
            }
        }
    }
    
    @objc func updateScore() {
        print("Updating Scores")
        if let scoreItem = realm.objects(ScoreItem.self).first
        {
            try! realm.write {
                scoreItem.Score += 1
            }
        }
    }
    
    private func createCircleShapeLayer(strokeColor: UIColor, fillColor: UIColor) -> CAShapeLayer {
        let layer = CAShapeLayer()
        let circularPath = UIBezierPath(arcCenter: .zero, radius: 50, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
        layer.path = circularPath.cgPath
        layer.strokeColor = strokeColor.cgColor
        layer.lineWidth = 20
        layer.fillColor = fillColor.cgColor
        layer.lineCap = CAShapeLayerLineCap.round
        layer.position = view.center
        return layer
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkingScoreSystem()
        let scores = UIBarButtonItem(title: "Update", style: .plain, target: self, action: #selector(updateScore))
        navigationItem.rightBarButtonItems = [scores]
        title = "Odd Job Scores"
        view.backgroundColor = UIColor.navyTheme
        setupCircleLayers()
        animateCircle()
        setupUserLabels()        
    }
    
    private func setupUserLabels() {
        view.addSubview(scoreLabel)
        scoreLabel.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        scoreLabel.center = view.center
        view.addSubview(userLabel)
        userLabel.translatesAutoresizingMaskIntoConstraints = false
        userLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        userLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 100).isActive = true
        userLabel.widthAnchor.constraint(equalToConstant: 200).isActive = true
        userLabel.heightAnchor.constraint(equalToConstant: 200).isActive = true
        
    }
    
    private func setupCircleLayers() {
        pulsatingLayer = createCircleShapeLayer(strokeColor: .clear, fillColor: UIColor.pulsatingFillColor)
        view.layer.addSublayer(pulsatingLayer)
        animatePulsatingLayer()
        let trackLayer = createCircleShapeLayer(strokeColor: .trackStrokeColor, fillColor: .backgroundColor)
        view.layer.addSublayer(trackLayer)
        shapeLayer = createCircleShapeLayer(strokeColor: .outlineStrokeColor, fillColor: .clear)
        shapeLayer.transform = CATransform3DMakeRotation(-CGFloat.pi / 2, 0, 0, 1)
        shapeLayer.strokeEnd = 0
        view.layer.addSublayer(shapeLayer)
    }
    
    private func animatePulsatingLayer() {
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.toValue = 1.1
        animation.duration = 0.8
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
        animation.autoreverses = true
        animation.repeatCount = Float.infinity
        pulsatingLayer.add(animation, forKey: "pulsing")
    }
    
    fileprivate func animateCircle() {
        let scoreItem = realm.objects(ScoreItem.self).first
        let points = scoreItem!.Score
        let basicAnimation = CABasicAnimation(keyPath: "strokeEnd")
        basicAnimation.toValue = CGFloat(points) / 100
        basicAnimation.duration = 2
        basicAnimation.fillMode = CAMediaTimingFillMode.forwards
        basicAnimation.isRemovedOnCompletion = false
        shapeLayer.add(basicAnimation, forKey: "Personal")
        scoreLabel.text = String(points)
        userLabel.text = "USER"
    }
    
    @objc private func handleTap() {
        print("Attempting to animate stroke")
    }
}
