/**
 * 存储模块
 * 负责 IndexedDB 和 localStorage 操作
 */

const Storage = {
  db: null,
  dbName: 'ColaSimulatorDB',
  dbVersion: 1,

  /**
   * 初始化数据库
   */
  initDB() {
    return new Promise((resolve, reject) => {
      const request = indexedDB.open(this.dbName, this.dbVersion);

      request.onupgradeneeded = (e) => {
        this.db = e.target.result;
        
        // 创建历史记录存储
        if (!this.db.objectStoreNames.contains('history')) {
          const store = this.db.createObjectStore('history', { keyPath: 'id' });
          store.createIndex('date', 'date', { unique: false });
          store.createIndex('simulator', 'simulator', { unique: false });
        }
        
        // 创建设置存储
        if (!this.db.objectStoreNames.contains('settings')) {
          this.db.createObjectStore('settings', { keyPath: 'key' });
        }
      };

      request.onsuccess = (e) => {
        this.db = e.target.result;
        console.log('[Storage] 数据库初始化完成');
        resolve(this.db);
      };

      request.onerror = (e) => {
        console.error('[Storage] 数据库初始化失败:', e.target.error);
        reject(e.target.error);
      };
    });
  },

  /**
   * 保存历史记录
   */
  saveHistory(record) {
    return new Promise((resolve, reject) => {
      if (!this.db) {
        reject(new Error('数据库未初始化'));
        return;
      }

      const transaction = this.db.transaction(['history'], 'readwrite');
      const store = transaction.objectStore('history');
      const request = store.add(record);

      request.onsuccess = () => {
        console.log('[Storage] 历史记录已保存');
        resolve(record);
      };

      request.onerror = (e) => {
        console.error('[Storage] 保存历史记录失败:', e.target.error);
        reject(e.target.error);
      };
    });
  },

  /**
   * 加载历史记录
   */
  loadHistory() {
    return new Promise((resolve, reject) => {
      if (!this.db) {
        reject(new Error('数据库未初始化'));
        return;
      }

      const transaction = this.db.transaction(['history'], 'readonly');
      const store = transaction.objectStore('history');
      const request = store.getAll();

      request.onsuccess = () => {
        resolve(request.result);
      };

      request.onerror = (e) => {
        reject(e.target.error);
      };
    });
  },

  /**
   * 删除历史记录
   */
  deleteHistory(id) {
    return new Promise((resolve, reject) => {
      if (!this.db) {
        reject(new Error('数据库未初始化'));
        return;
      }

      const transaction = this.db.transaction(['history'], 'readwrite');
      const store = transaction.objectStore('history');
      const request = store.delete(id);

      request.onsuccess = () => {
        resolve();
      };

      request.onerror = (e) => {
        reject(e.target.error);
      };
    });
  },

  /**
   * 清空历史记录
   */
  clearHistory() {
    return new Promise((resolve, reject) => {
      if (!this.db) {
        reject(new Error('数据库未初始化'));
        return;
      }

      const transaction = this.db.transaction(['history'], 'readwrite');
      const store = transaction.objectStore('history');
      const request = store.clear();

      request.onsuccess = () => {
        resolve();
      };

      request.onerror = (e) => {
        reject(e.target.error);
      };
    });
  },

  /**
   * 保存设置
   */
  saveSetting(key, value) {
    return new Promise((resolve, reject) => {
      if (!this.db) {
        reject(new Error('数据库未初始化'));
        return;
      }

      const transaction = this.db.transaction(['settings'], 'readwrite');
      const store = transaction.objectStore('settings');
      const request = store.put({ key, value });

      request.onsuccess = () => {
        resolve();
      };

      request.onerror = (e) => {
        reject(e.target.error);
      };
    });
  },

  /**
   * 加载设置
   */
  loadSetting(key) {
    return new Promise((resolve, reject) => {
      if (!this.db) {
        reject(new Error('数据库未初始化'));
        return;
      }

      const transaction = this.db.transaction(['settings'], 'readonly');
      const store = transaction.objectStore('settings');
      const request = store.get(key);

      request.onsuccess = () => {
        resolve(request.result ? request.result.value : null);
      };

      request.onerror = (e) => {
        reject(e.target.error);
      };
    });
  },

  /**
   * 保存到 localStorage（用于简单数据）
   */
  saveToLocal(key, value) {
    try {
      localStorage.setItem(key, JSON.stringify(value));
    } catch (e) {
      console.error('[Storage] localStorage 保存失败:', e);
    }
  },

  /**
   * 从 localStorage 加载
   */
  loadFromLocal(key) {
    try {
      const item = localStorage.getItem(key);
      return item ? JSON.parse(item) : null;
    } catch (e) {
      console.error('[Storage] localStorage 加载失败:', e);
      return null;
    }
  }
};

// 导出模块
window.Storage = Storage;
