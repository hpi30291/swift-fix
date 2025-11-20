import Foundation

struct Question: Identifiable, Codable {
    let id: String
    let questionText: String
    let answerA: String?
    let answerB: String?
    let answerC: String?
    let answerD: String?
    let correctAnswer: String
    let category: String
    var explanation: String? = nil
    var imageName: String? = nil  // Optional image asset name for signs

    // Shuffle answers to prevent patterns (used for diagnostic/exam)
    func withShuffledAnswers() -> Question {
        // Collect all answers with their original letters
        var answers: [(letter: String, text: String)] = []
        if let a = answerA { answers.append(("A", a)) }
        if let b = answerB { answers.append(("B", b)) }
        if let c = answerC { answers.append(("C", c)) }
        if let d = answerD { answers.append(("D", d)) }

        // Shuffle the answers
        let shuffled = answers.shuffled()

        // Find where the correct answer ended up
        guard let originalCorrectIndex = answers.firstIndex(where: { $0.letter == correctAnswer }) else {
            return self // Safety fallback
        }
        let correctAnswerText = answers[originalCorrectIndex].text
        guard let newCorrectIndex = shuffled.firstIndex(where: { $0.text == correctAnswerText }) else {
            return self // Safety fallback
        }
        let newCorrectLetter = ["A", "B", "C", "D"][newCorrectIndex]

        // Create new question with shuffled answers
        return Question(
            id: id,
            questionText: questionText,
            answerA: shuffled.count > 0 ? shuffled[0].text : nil,
            answerB: shuffled.count > 1 ? shuffled[1].text : nil,
            answerC: shuffled.count > 2 ? shuffled[2].text : nil,
            answerD: shuffled.count > 3 ? shuffled[3].text : nil,
            correctAnswer: newCorrectLetter,
            category: category,
            explanation: explanation,
            imageName: imageName
        )
    }
}
