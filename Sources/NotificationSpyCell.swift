import UIKit

class NotificationSpyCell: UITableViewCell {

    static public let reuseID = "NotificationSpyCell"

    static public func registerFor(tableView: UITableView) {
        let nib: UINib = UINib(nibName: reuseID, bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: reuseID)
    }

    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var sender: UILabel!

    public func configure(_ note: Note) {
        var color = UIColor.black
        if note.name.hasPrefix("AFUIViewController") {
            color = UIColor.red
        } else
        if note.name.hasPrefix("UIViewController") {
            color = UIColor.blue
        }
        name.text = note.name
        name.textColor = color
        sender.text = note.sender
        sender.textColor = color
    }
}
