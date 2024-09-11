//
//  Bible.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/1/24.
//

import SwiftUI

struct Book: Codable {
    let name: String
    let description: String
    let chapters: [Chapter]

    private enum CodingKeys: String, CodingKey {
        case name, description, chapters
    }

    init(name: String, description: String, chapters: [Chapter]) {
        self.name = name
        self.description = description
        self.chapters = chapters
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        chapters = try container.decode([Chapter].self, forKey: .chapters)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(chapters, forKey: .chapters)
    }

    static let genesis = Book(
          name: "Genesis",
          description: "The beginning",
          chapters: [
              .init(number: 1, paragraphs: [
                  .init(startingVerse: 1, text: "In the beginning God created the heaven and the earth."),
                  .init(startingVerse: 2, text: "And the earth was without form, and void; and darkness was upon the face of the deep. And the Spirit of God moved upon the face of the waters."),
                  .init(startingVerse: 3, text: "And God said, Let there be light: and there was light."),
                  .init(startingVerse: 4, text: "And God saw the light, that it was good: and God divided the light from the darkness."),
                  .init(startingVerse: 5, text: "And God called the light Day, and the darkness he called Night. And the evening and the morning were the first day."),
                  .init(startingVerse: 6, text: "And God said, Let there be a firmament in the midst of the waters, and let it divide the waters from the waters."),
                  .init(startingVerse: 7, text: "And God made the firmament, and divided the waters which were under the firmament from the waters which were above the firmament: and it was so."),
                  .init(startingVerse: 8, text: "And God called the firmament Heaven. And the evening and the morning were the second day."),
                  .init(startingVerse: 9, text: "And God said, Let the waters under the heaven be gathered together unto one place, and let the dry land appear: and it was so."),
                  .init(startingVerse: 10, text: "And God called the dry land Earth; and the gathering together of the waters called he Seas: and God saw that it was good."),
                  .init(startingVerse: 11, text: "And God said, Let the earth bring forth grass, the herb yielding seed, and the fruit tree yielding fruit after his kind, whose seed is in itself, upon the earth: and it was so."),
                  .init(startingVerse: 12, text: "And the earth brought forth grass, and herb yielding seed after his kind, and the tree yielding fruit, whose seed was in itself, after his kind: and God saw that it was good."),
                  .init(startingVerse: 13, text: "And the evening and the morning were the third day."),
                  .init(startingVerse: 14, text: "And God said, Let there be lights in the firmament of the heaven to divide the day from the night; and let them be for signs, and for seasons, and for days, and years:"),
                  .init(startingVerse: 15, text: "And let them be for lights in the firmament of the heaven to give light upon the earth: and it was so."),
                  .init(startingVerse: 16, text: "And God made two great lights; the greater light to rule the day, and the lesser light to rule the night: he made the stars also."),
                  .init(startingVerse: 17, text: "And God set them in the firmament of the heaven to give light upon the earth,"),
                  .init(startingVerse: 18, text: "And to rule over the day and over the night, and to divide the light from the darkness: and God saw that it was good."),
                  .init(startingVerse: 19, text: "And the evening and the morning were the fourth day."),
                  .init(startingVerse: 20, text: "And God said, Let the waters bring forth abundantly the moving creature that hath life, and fowl that may fly above the earth in the open firmament of heaven."),
                  .init(startingVerse: 21, text: "And God created great whales, and every living creature that moveth, which the waters brought forth abundantly, after their kind, and every winged fowl after his kind: and God saw that it was good."),
                  .init(startingVerse: 22, text: "And God blessed them, saying, Be fruitful, and multiply, and fill the waters in the seas, and let fowl multiply in the earth."),
                  .init(startingVerse: 23, text: "And the evening and the morning were the fifth day."),
                  .init(startingVerse: 24, text: "And God said, Let the earth bring forth the living creature after his kind, cattle, and creeping thing, and beast of the earth after his kind: and it was so."),
                  .init(startingVerse: 25, text: "And God made the beast of the earth after his kind, and cattle after their kind, and every thing that creepeth upon the earth after his kind: and God saw that it was good."),
                  .init(startingVerse: 26, text: "And God said, Let us make man in our image, after our likeness: and let them have dominion over the fish of the sea, and over the fowl of the air, and over the cattle, and over all the earth, and over every creeping thing that creepeth upon the earth."),
                  .init(startingVerse: 27, text: "So God created man in his own image, in the image of God created he him; male and female created he them."),
                  .init(startingVerse: 28, text: "And God blessed them, and God said unto them, Be fruitful, and multiply, and replenish the earth, and subdue it: and have dominion over the fish of the sea, and over the fowl of the air, and over every living thing that moveth upon the earth."),
                  .init(startingVerse: 29, text: "And God said, Behold, I have given you every herb bearing seed, which is upon the face of all the earth, and every tree, in the which is the fruit of a tree yielding seed; to you it shall be for meat."),
                  .init(startingVerse: 30, text: "And to every beast of the earth, and to every fowl of the air, and to every thing that creepeth upon the earth, wherein there is life, I have given every green herb for meat: and it was so."),
                  .init(startingVerse: 31, text: "And God saw every thing that he had made, and, behold, it was very good. And the evening and the morning were the sixth day.")
              ]),
              .init(number: 2, paragraphs: [
                  .init(startingVerse: 1, text: "Thus the heavens and the earth were finished, and all the host of them."),
                  .init(startingVerse: 2, text: "And on the seventh day God ended his work which he had made; and he rested on the seventh day from all his work which he had made."),
                  .init(startingVerse: 3, text: "And God blessed the seventh day, and sanctified it: because that in it he had rested from all his work which God created and made."),
                  .init(startingVerse: 4, text: "These are the generations of the heavens and of the earth when they were created, in the day that the LORD God made the earth and the heavens,"),
                  .init(startingVerse: 5, text: "And every plant of the field before it was in the earth, and every herb of the field before it grew: for the LORD God had not caused it to rain upon the earth, and there was not a man to till the ground."),
                  .init(startingVerse: 6, text: "But there went up a mist from the earth, and watered the whole face of the ground."),
                  .init(startingVerse: 7, text: "And the LORD God formed man of the dust of the ground, and breathed into his nostrils the breath of life; and man became a living soul."),
                  .init(startingVerse: 8, text: "And the LORD God planted a garden eastward in Eden; and there he put the man whom he had formed."),
                  .init(startingVerse: 9, text: "And out of the ground made the LORD God to grow every tree that is pleasant to the sight, and good for food; the tree of life also in the midst of the garden, and the tree of knowledge of good and evil."),
                  .init(startingVerse: 10, text: "And a river went out of Eden to water the garden; and from thence it was parted, and became into four heads."),
                  .init(startingVerse: 11, text: "The name of the first is Pison: that is it which compasseth the whole land of Havilah, where there is gold;"),
                  .init(startingVerse: 12, text: "And the gold of that land is good: there is bdellium and the")
                  ]),
              ])

    var testament: Testament? = .old
    var version: Version = .kjv
}
