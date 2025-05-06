{ pkgs }: with pkgs; let
  font = {
    mediumItalic = fetchurl {
      url = "https://drive.home.soraliu.dev/dav/fonts/SauceCodeProNerdFontMono-MediumItalic.ttf";
      hash = "sha256-N9L57FiiwlO2vzEMP6eLWLUW9omvfx812AEWgg2cd2c=";
    };
    medium = fetchurl {
      url = "https://drive.home.soraliu.dev/dav/fonts/SauceCodeProNerdFontMono-Medium.ttf";
      hash = "sha256-wE9zp+h6hiO8qq5DXYsfEt6NGXdigCxUQbjzNGWFjhY=";
    };
  };
in font
