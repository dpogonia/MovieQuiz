//
//  MovieQuizLoadingView.swift
//  MovieQuiz
//
//  Created by Dmitrii Pogonia on 18.04.2026.
//

import UIKit

final class MovieQuizLoadingView: UIView {
    
    private let blurView: UIVisualEffectView = {
        let effect = UIBlurEffect(style: .systemThickMaterialDark)
        return UIVisualEffectView(effect: effect)
    }()
    
    private let contentStack: UIStackView = {
        let s = UIStackView()
        s.translatesAutoresizingMaskIntoConstraints = false
        s.axis = .vertical
        s.alignment = .center
        s.spacing = 16
        return s
    }()
    
    private let iconView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.shadowColor = UIColor.ypGreen.cgColor
        v.layer.shadowRadius = 16
        v.layer.shadowOpacity = 0.45
        v.layer.shadowOffset = .zero
        return v
    }()
    
    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.tintColor = .ypWhite
        iv.contentMode = .scaleAspectFit
        let config = UIImage.SymbolConfiguration(pointSize: 56, weight: .light)
        iv.image = UIImage(systemName: "film", withConfiguration: config)
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.textAlignment = .center
        l.textColor = .ypWhite
        l.font = .systemFont(ofSize: 20, weight: .semibold)
        l.text = "Сеанс скоро начнется"
        l.numberOfLines = 0
        return l
    }()
    
    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.textAlignment = .center
        l.textColor = .ypWhite.withAlphaComponent(0.85)
        l.font = .systemFont(ofSize: 15, weight: .regular)
        l.numberOfLines = 0
        l.text = "Загружаем киноленту, нарезаем кадры и настраиваем звук..."
        return l
    }()
    
    private let filmstripLayer: CAGradientLayer = {
        let g = CAGradientLayer()
        g.colors = [
            UIColor.ypGreen.withAlphaComponent(0.6).cgColor,
            UIColor.ypRed.withAlphaComponent(0.35).cgColor,
            UIColor.ypGreen.withAlphaComponent(0.5).cgColor
        ]
        g.startPoint = CGPoint(x: 0, y: 0.5)
        g.endPoint = CGPoint(x: 1, y: 0.5)
        g.locations = [0, 0.5, 1]
        return g
    }()
    
    private let filmStripHost = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .ypBlack.withAlphaComponent(0.35)
        
        addSubview(blurView)
        addSubview(filmStripHost)
        addSubview(contentStack)
        
        blurView.translatesAutoresizingMaskIntoConstraints = false
        filmStripHost.translatesAutoresizingMaskIntoConstraints = false
        filmStripHost.layer.addSublayer(filmstripLayer)
        filmStripHost.isUserInteractionEnabled = false
        
        iconView.addSubview(iconImageView)
        contentStack.addArrangedSubview(iconView)
        contentStack.setCustomSpacing(20, after: iconView)
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(subtitleLabel)
        contentStack.addArrangedSubview(filmStripHost)
        contentStack.setCustomSpacing(12, after: subtitleLabel)
        
        let stripHeight: CGFloat = 4
        let guide = safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            contentStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            contentStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            contentStack.leadingAnchor.constraint(greaterThanOrEqualTo: guide.leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(lessThanOrEqualTo: guide.trailingAnchor, constant: -24),
            
            iconView.widthAnchor.constraint(equalToConstant: 88),
            iconView.heightAnchor.constraint(equalToConstant: 88),
            
            iconImageView.centerXAnchor.constraint(equalTo: iconView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            iconImageView.widthAnchor.constraint(lessThanOrEqualTo: iconView.widthAnchor),
            iconImageView.heightAnchor.constraint(lessThanOrEqualTo: iconView.heightAnchor),
            
            filmStripHost.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.62),
            filmStripHost.heightAnchor.constraint(equalToConstant: stripHeight)
        ])
        
        isHidden = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let w = filmStripHost.bounds.width
        filmstripLayer.frame = filmStripHost.bounds
        if w > 0 { filmStripHost.layer.cornerRadius = filmStripHost.bounds.height / 2 }
    }
    
    func setAnimating(_ animating: Bool) {
        if animating {
            isHidden = false
            startIconPulse()
            startShimmer()
        } else {
            isHidden = true
            stopAnimations()
        }
    }
    
    private func startIconPulse() {
        let pulse = CABasicAnimation(keyPath: "transform.scale")
        pulse.fromValue = 1.0
        pulse.toValue = 1.08
        pulse.duration = 0.9
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        iconImageView.layer.add(pulse, forKey: "pulse")
    }
    
    private func startShimmer() {
        let shift = CABasicAnimation(keyPath: "colors")
        shift.fromValue = [
            UIColor.ypGreen.withAlphaComponent(0.4).cgColor,
            UIColor.ypRed.withAlphaComponent(0.25).cgColor,
            UIColor.ypGreen.withAlphaComponent(0.4).cgColor
        ]
        shift.toValue = [
            UIColor.ypRed.withAlphaComponent(0.35).cgColor,
            UIColor.ypGreen.withAlphaComponent(0.5).cgColor,
            UIColor.ypRed.withAlphaComponent(0.3).cgColor
        ]
        shift.duration = 1.6
        shift.autoreverses = true
        shift.repeatCount = .infinity
        filmstripLayer.add(shift, forKey: "shimmer")
        
        let loc = CAKeyframeAnimation(keyPath: "locations")
        loc.values = [
            [0, 0.2, 0.45],
            [0.1, 0.55, 0.9],
            [0, 0.2, 0.45]
        ]
        loc.duration = 2.4
        loc.repeatCount = .infinity
        loc.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        filmstripLayer.add(loc, forKey: "strip")
    }
    
    private func stopAnimations() {
        iconImageView.layer.removeAllAnimations()
        filmstripLayer.removeAllAnimations()
    }
}
