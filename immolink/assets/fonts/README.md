Place the following font files in this folder to enable embedded fonts in exported PDFs:

- NotoSans-Regular.ttf
- NotoSans-Bold.ttf

Download from Google Fonts (Noto Sans):
https://fonts.google.com/specimen/Noto+Sans

License: SIL Open Font License 1.1
https://scripts.sil.org/OFL

After adding the files, run:

```
flutter pub get
```

Then export a report again; the PDF will use the embedded fonts automatically with a fallback if the files are not present.