/**
 * 像素猫主题生成器
 * 代码生成的像素艺术猫咪，去除 AI 味
 */

const PixelCatTheme = {
  // 像素猫设计（16x16 网格）
  // 使用简单的字符画风格，不那么精致但有特色
  catDesign: [
    '................',
    '...XX......XX...',
    '..XXXX....XXXX..',
    '.XXXXXX..XXXXXX.',
    '.XXXXXX..XXXXXX.',
    '..XXXXXXXXXXXX..',
    '...XXXXXXXXXX...',
    '....XXXXXXXX....',
    '.....XXXXXX.....',
    '......XXXX......',
    '......XXXX......',
    '.....X..XX..X...',
    '....XX..XX..XX..',
    '...XXX..XX..XXX.',
    '................',
    '................'
  ],
  
  // 颜色方案（二次元配色）
  colors: {
    primary: '#ff6b9d',    // 粉色
    secondary: '#c77dff',  // 紫色
    accent: '#00f0ff',     // 青色
    dark: '#1a1a2e',       // 深色
    light: '#ffffff'       // 白色
  },
  
  /**
   * 生成像素猫 Canvas
   */
  generateCanvas(size = 64) {
    const canvas = document.createElement('canvas');
    canvas.width = size;
    canvas.height = size;
    const ctx = canvas.getContext('2d');
    
    const pixelSize = size / 16;
    
    // 清空画布
    ctx.fillStyle = 'transparent';
    ctx.fillRect(0, 0, size, size);
    
    // 绘制像素猫
    this.catDesign.forEach((row, y) => {
      for (let x = 0; x < row.length; x++) {
        if (row[x] === 'X') {
          // 渐变效果
          const gradient = ctx.createLinearGradient(
            x * pixelSize, y * pixelSize,
            (x + 1) * pixelSize, (y + 1) * pixelSize
          );
          gradient.addColorStop(0, this.colors.primary);
          gradient.addColorStop(1, this.colors.secondary);
          
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
   * 生成像素猫 SVG
   */
  generateSVG(size = 64) {
    const pixelSize = size / 16;
    let rects = '';
    
    this.catDesign.forEach((row, y) => {
      for (let x = 0; x < row.length; x++) {
        if (row[x] === 'X') {
          rects += `<rect x="${x * pixelSize}" y="${y * pixelSize}" width="${pixelSize - 1}" height="${pixelSize - 1}" fill="url(#catGradient)"/>`;
        }
      }
    });
    
    return `
      <svg width="${size}" height="${size}" viewBox="0 0 ${size} ${size}" xmlns="http://www.w3.org/2000/svg">
        <defs>
          <linearGradient id="catGradient" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:${this.colors.primary}"/>
            <stop offset="100%" style="stop-color:${this.colors.secondary}"/>
          </linearGradient>
        </defs>
        ${rects}
      </svg>
    `;
  },
  
  /**
   * 生成 CSS 背景
   */
  generateCSSBackground() {
    // 将像素猫转换为 base64 用于 CSS
    const canvas = this.generateCanvas(32);
    const dataURL = canvas.toDataURL('image/png');
    
    return `
      background-image: url("${dataURL}");
      background-repeat: no-repeat;
      background-position: center;
      background-size: contain;
    `;
  },
  
  /**
   * 应用主题到页面
   */
  applyToPage() {
    // 设置 favicon
    const svgData = this.generateSVG(64);
    const svgBlob = new Blob([svgData], { type: 'image/svg+xml' });
    const url = URL.createObjectURL(svgBlob);
    
    const link = document.querySelector('link[rel="icon"]');
    if (link) {
      link.href = url;
    }
    
    // 添加像素猫装饰到页面
    this.addPageDecorations();
    
    console.log('[PixelCat] 主题已应用');
  },
  
  /**
   * 添加页面装饰
   */
  addPageDecorations() {
    // 创建像素猫装饰元素
    const decorations = [
      { position: 'top-left', offset: '20px' },
      { position: 'top-right', offset: '20px' }
    ];
    
    decorations.forEach(config => {
      const cat = this.generateCanvas(48);
      cat.style.position = 'fixed';
      cat.style[config.position] = config.offset;
      cat.style.top = config.position.includes('top') ? config.offset : 'auto';
      cat.style.bottom = config.position.includes('bottom') ? config.offset : 'auto';
      cat.style.zIndex = '9999';
      cat.style.opacity = '0.8';
      cat.style.pointerEvents = 'none';
      
      document.body.appendChild(cat);
    });
  },
  
  /**
   * 生成加载动画
   */
  generateLoadingAnimation() {
    const container = document.createElement('div');
    container.className = 'pixel-cat-loading';
    
    const cat = this.generateCanvas(64);
    cat.style.animation = 'bounce 1s infinite';
    
    container.appendChild(cat);
    
    // 添加 CSS 动画
    const style = document.createElement('style');
    style.textContent = `
      @keyframes bounce {
        0%, 100% { transform: translateY(0); }
        50% { transform: translateY(-10px); }
      }
      .pixel-cat-loading {
        position: fixed;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        z-index: 10000;
      }
    `;
    document.head.appendChild(style);
    
    return container;
  }
};

// 导出模块
window.PixelCatTheme = PixelCatTheme;
