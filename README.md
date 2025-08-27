# Roulette Casino Game

## Опис
Мобільна гра в рулетку для iOS з використанням SwiftUI та Firebase. Включає класичну рулетку та режим 1 на 1.

## Функції
- Європейська рулетка (0-36)
- Всі типи ставок (straight up, split, street, corner, line, dozen, column, color, odd/even, low/high)
- Режим 1 на 1 з ботом
- Рейтинг гравців
- Анонімна реєстрація та Google Sign-In
- 2000 фішок при реєстрації
- Бонусні фішки при закінченні балансу
- Налаштування з кнопками Rate App та Share App

## Технології
- SwiftUI
- Firebase (Auth, Firestore)
- Google Sign-In
- Lottie анімації
- AVFoundation

## Запуск
1. Відкрити test_game.xcodeproj в Xcode
2. Налаштувати Firebase (додати GoogleService-Info.plist)
3. Включити Authentication та Firestore в Firebase Console
4. Запустити на симуляторі або пристрої

## Архітектура
- MVVM патерн
- Розділення на ViewModels, Views, Models
- Firebase для збереження даних користувачів

## Особливості
- Анімоване колесо рулетки
- Система ставок з перевіркою балансу
- Таймер 60 секунд в режимі 1 на 1
- Рейтинг топ 50 гравців
- Фонова музика з можливістю вимкнення
