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
    var scoreItem: Results<ScoreItem>
    var shapeLayer = CAShapeLayer()
    var pulsatingLayer = CAShapeLayer()
    let userDetails = LoginViewController()
    var scoreActive = true
    let levelLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 32)
        label.textColor = .white
        return label
    }()
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
        label.font = UIFont.boldSystemFont(ofSize: 15)
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
        self.scoreItem = realm.objects(ScoreItem.self).filter("Category contains[c] %@", "Personal")
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //Score System Checks
    fileprivate func checkingScoreSystem() {
        print("Checking Scoring System.")
        if realm.objects(ScoreItem.self).count != 0
        {
            print("Score already exists.")
        } else {
            for field in Constants.listTypes {
                let newScore = ScoreItem()
                newScore.Name = field
                newScore.Category = field
                try! self.realm.write {
                    self.realm.add(newScore)
                    print("Creating score for list: " + String(newScore.Category))
                }
            }
        }
    }
    
    @objc func updateScore() {
        print("Updating Scores")
        for update in Constants.listTypes {
            let scores = realm.objects(ScoreItem.self).filter("Category contains[c] %@", update)
            if let score = scores.first {
                if score.Score == score.LevelCap {
                    try! realm.write {
                        score.Score = 0
                        score.Level += 1
                        score.TotalScore += 1
                    }
                }
                else {
                    try! realm.write {
                        score.Score += 1
                        score.TotalScore += 1
                    }
                }
            }
        }
        animateCircle()
    }
    
    private func createCircleShapeLayer(strokeColor: UIColor, fillColor: UIColor) -> CAShapeLayer {
        let layer = CAShapeLayer()
        //let postition = CGPoint(x: 100,y: 100)
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
        let scores = UIBarButtonItem(title: "Update", style: .plain, target: self, action: #selector(updateScore))
        navigationItem.rightBarButtonItems = [scores]
        navigationItem.title = "Scores"
        view.backgroundColor = UIColor.navyTheme
        checkingScoreSystem()
        setupCircleLayers()
        //animateCircle()
        setupUserLabels()
        increaseLabel()
    }
    
    private func setupUserLabels() {
        view.addSubview(scoreLabel)
        scoreLabel.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        scoreLabel.center = view.center
        view.addSubview(userLabel)
        userLabel.translatesAutoresizingMaskIntoConstraints = false
        userLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        userLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 10).isActive = true
        userLabel.widthAnchor.constraint(equalToConstant: 200).isActive = true
        userLabel.heightAnchor.constraint(equalToConstant: 200).isActive = true
        view.addSubview(levelLabel)
        levelLabel.translatesAutoresizingMaskIntoConstraints = false
        levelLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        levelLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 50).isActive = true
        levelLabel.widthAnchor.constraint(equalToConstant: 200).isActive = true
        levelLabel.heightAnchor.constraint(equalToConstant: 200).isActive = true
        
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
        animation.toValue = 1.3
        animation.duration = 0.8
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
        animation.autoreverses = true
        animation.repeatCount = Float.infinity
        pulsatingLayer.add(animation, forKey: "pulsing")
    }
    
    func animateCircle() {
        let scoreItem = realm.objects(ScoreItem.self).first
        let basicAnimation = CABasicAnimation(keyPath: "strokeEnd")
        basicAnimation.fromValue = CGFloat(scoreItem!.Score - 1) / CGFloat(scoreItem!.LevelCap)
        basicAnimation.toValue = CGFloat(scoreItem!.Score) / CGFloat(scoreItem!.LevelCap)
        basicAnimation.duration = 2
        basicAnimation.fillMode = CAMediaTimingFillMode.forwards
        basicAnimation.isRemovedOnCompletion = false
        shapeLayer.add(basicAnimation, forKey: "Personal")
        scoreLabel.text = String(scoreItem!.Score)
        userLabel.text = UserDefaults.standard.string(forKey: "Name") ?? ""
        levelLabel.text = String("Level: " + String(scoreItem!.Level))
    }
    
    /*
     Constantly check for updates to scores
    */
    func increaseLabel() {
        let scoreItem = realm.objects(ScoreItem.self).first
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            if self.scoreActive {
                self.scoreLabel.text = "\(scoreItem!.Score)"
                self.levelLabel.text = "Level: " + "\(scoreItem!.Level)"
                self.increaseLabel()
                self.animateCircle()
            }
        }
    }
}
