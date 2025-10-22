#!/usr/bin/env python3
"""
GitHub Pages セットアップ - Seleniumを使用したブラウザ自動化
"""
import os
import sys
import time

# Selenium インストール確認
try:
    from selenium import webdriver
    from selenium.webdriver.common.by import By
    from selenium.webdriver.support.ui import Select, WebDriverWait
    from selenium.webdriver.support import expected_conditions as EC
    print("✅ Selenium 利用可能")
except ImportError:
    print("❌ Selenium が見つかりません。インストール中...")
    os.system("pip install selenium -q")
    from selenium import webdriver
    from selenium.webdriver.common.by import By
    from selenium.webdriver.support.ui import Select, WebDriverWait
    from selenium.webdriver.support import expected_conditions as EC

# GitHub credentials
GITHUB_USERNAME = os.environ.get('GITHUB_USERNAME')
GITHUB_PASSWORD = os.environ.get('GITHUB_PASSWORD')

if not GITHUB_USERNAME or not GITHUB_PASSWORD:
    print("❌ GitHub credentials が必要です")
    print("")
    print("環境変数を設定してください:")
    print("  export GITHUB_USERNAME='your_username'")
    print("  export GITHUB_PASSWORD='your_password'")
    print("")
    print("または Personal Access Token を使用:")
    print("  export GITHUB_TOKEN='ghp_xxxxx...'")
    exit(1)

print("🔍 Chrome ブラウザを起動中...")

try:
    # Chrome オプション
    chrome_options = webdriver.ChromeOptions()
    chrome_options.add_argument('--no-sandbox')
    chrome_options.add_argument('--disable-dev-shm-usage')
    
    driver = webdriver.Chrome(options=chrome_options)
    print("✅ Chrome 起動成功")
    
except Exception as e:
    print(f"❌ Chrome 起動失敗: {e}")
    print("代替方法: Firefox ドライバーを試します...")
    try:
        driver = webdriver.Firefox()
    except:
        print("❌ ブラウザドライバーが見つかりません")
        exit(1)

try:
    # GitHub ログインページにアクセス
    print("📍 GitHub ログインページにアクセス...")
    driver.get("https://github.com/login")
    time.sleep(2)
    
    # ログイン
    print("🔐 ログイン中...")
    username_input = driver.find_element(By.ID, "login_field")
    password_input = driver.find_element(By.ID, "password")
    
    username_input.send_keys(GITHUB_USERNAME)
    password_input.send_keys(GITHUB_PASSWORD)
    
    # ログインボタンをクリック
    login_button = driver.find_element(By.NAME, "commit")
    login_button.click()
    
    time.sleep(3)
    
    # GitHub Pages 設定ページにアクセス
    print("📄 GitHub Pages 設定ページにアクセス...")
    pages_url = "https://github.com/pj0201/Claude-Code-Communication/settings/pages"
    driver.get(pages_url)
    
    time.sleep(3)
    
    # Source セレクターを探す
    print("🎯 Source セレクターを確認中...")
    
    # "Deploy from a branch" ボタンを探す
    try:
        branch_source = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.XPATH, "//input[@value='branch']"))
        )
        print("✅ 'Deploy from a branch' オプションが見つかりました")
        
        # クリック
        branch_source.click()
        time.sleep(1)
        
        # ブランチセレクト
        print("🌿 Branch を選択中...")
        branch_select = Select(driver.find_element(By.ID, "pages-source-branch"))
        branch_select.select_by_value("master")
        
        time.sleep(1)
        
        # フォルダセレクト
        print("📁 Folder を選択中...")
        folder_select = Select(driver.find_element(By.ID, "pages-source-path"))
        folder_select.select_by_value("/docs")
        
        time.sleep(1)
        
        # Save ボタン
        print("💾 Save ボタンをクリック...")
        save_button = driver.find_element(By.XPATH, "//button[contains(text(), 'Save')]")
        save_button.click()
        
        time.sleep(3)
        
        print("✅ GitHub Pages 設定が更新されました！")
        
    except Exception as e:
        print(f"❌ 要素の検出に失敗: {e}")
        print(f"現在のURL: {driver.current_url}")
        print(f"ページタイトル: {driver.title}")
        
finally:
    print("🔒 ブラウザを閉じています...")
    driver.quit()
    print("✅ 完了")

