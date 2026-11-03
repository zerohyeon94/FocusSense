# Orot 개발 안내

- 공통 작업 규칙은 루트 `CLAUDE.md`를 읽습니다.
- iOS 작업 전 `apps/ios/CLAUDE.md`, 웹은 `apps/web/CLAUDE.md`, ML은 `research/ml/CLAUDE.md`를 읽습니다.
- 현재 디렉터리 책임과 호환성 경계는 `docs/architecture/repository-structure.md`를 참고합니다.
- 제품 기획서의 예시 코드와 향후 계획은 현재 구현과 구분합니다. 구조 이동만으로 감지 정책이나 데이터 스키마를 바꾸지 않습니다.
- Bundle ID, 저장 모델 이름, UserDefaults 키, 기존 CoreML 산출물 이름은 호환성 검토 없이 일괄 변경하지 않습니다.
- 미커밋 사용자 변경을 보존하며, 폴더 이동 시 Xcode 파일 참조·스킴·빌드 설정도 함께 확인합니다.
