// Book+SampleData.swift
#if DEBUG
extension Book {
    static var sampleBooks: [Book] {
        [
            Book(title: "Мастер и Маргарита",
                 author: "М. Булгаков",
                 filePath: "",
                 format: "epub",
                 source: "local"),
            Book(title: "Dune",
                 author: "Frank Herbert",
                 filePath: "",
                 format: "pdf",
                 source: "icloud",
                 fileSize: 4_200_000),
            Book(title: "Война и мир",
                 author: "Л. Толстой",
                 filePath: "",
                 format: "fb2",
                 source: "webdav")
        ]
    }
}
#endif
