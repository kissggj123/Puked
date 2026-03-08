/**
 * 像素动物按钮组件
 * 为不同功能生成对应的像素动物图标
 */

const PixelAnimalButtons = {
  // 按钮对应的动物图标
  buttonAnimals: {
    start: 'cat',      // 开始 - 猫
    stop: 'dog',       // 停止 - 狗
    fullscreen: 'rabbit', // 全屏 - 兔子
    data: 'bear',      // 数据 - 熊
    professional: 'fox' // 专业仪表盘 - 狐狸
  },
  
  // 按钮对应的 Emoji
  buttonEmojis: {
    start: '▶',
    stop: '⏹',
    fullscreen: '⛶',
    data: '📊',
    professional: '🎛️'
  },
  
  /**
   * 生成像素动物图标 Canvas
   */
  generateButtonIcon(animalType, size = 24) {
    const design = PixelAnimalTheme.animals[animalType] || PixelAnimalTheme.animals.cat;
    const colors = PixelAnimalTheme.colorSchemes[animalType] || PixelAnimalTheme.colorSchemes.cat;
    
    const canvas = document.createElement('canvas');
    canvas.width = size;
    canvas.height = size;
    const ctx = canvas.getContext('2d');
    
    const pixelSize = size / 16;
    
    // 清空画布
    ctx.fillStyle = 'transparent';
    ctx.fillRect(0, 0, size, size);
    
    // 绘制像素动物
    design.forEach((row, y) => {
      for (let x = 0; x < row.length; x++) {
        if (row[x] === 'X') {
          // 渐变效果
          const gradient = ctx.createLinearGradient(
            x * pixelSize, y * pixelSize,
            (x + 1) * pixelSize, (y + 1) * pixelSize
          );
          gradient.addColorStop(0, colors.primary);
          gradient.addColorStop(1, colors.secondary);
          
          ctx.fillStyle = gradient;
          ctx.fillRect(
            x * pixelSize + 0.5,
            y * pixelSize + 0.5,
            pixelSize - 1,
            pixelSize - 1
          );
        }
      }
    });
    
    return canvas;
  },
  
  /**
   * 应用所有按钮图标
   */
  applyToButtons() {
    // 等待 DOM 加载完成
    setTimeout(() => {
      this.updateButtonIcons();
    }, 100);
  },
  
  /**
   * 更新按钮图标
   */
  updateButtonIcons() {
    // 查找所有按钮并添加对应的动物图标
    const buttons = document.querySelectorAll('.btn');
    
    buttons.forEach((btn, index) => {
      const text = btn.textContent.trim();
      let animalType = 'cat';
      
      // 根据按钮文本确定动物类型
      if (text.includes('开始')) {
        animalType = 'cat';
      } else if (text.includes('停止')) {
        animalType = 'dog';
      } else if (text.includes('全屏')) {
        animalType = 'rabbit';
      } else if (text.includes('数据')) {
        animalType = 'bear';
      } else if (text.includes('专业仪表')) {
        animalType = 'fox';
      }
      
      // 创建图标
      const icon = this.generateButtonIcon(animalType, 20);
      icon.style.verticalAlign = 'middle';
      icon.style.marginRight = '6px';
      
      // 保存原文本
      if (!btn.dataset.originalText) {
        btn.dataset.originalText = text;
      }
      
      // 清空按钮并添加图标和文本
      btn.innerHTML = '';
      btn.appendChild(icon);
      btn.appendChild(document.createTextNode(text));
    });
  }
};

// 导出模块
window.PixelAnimalButtons = PixelAnimalButtons;
