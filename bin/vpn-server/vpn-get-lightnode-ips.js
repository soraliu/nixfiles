#!/usr/bin/env node

let o,
  a,
  r,
  i = null;

let nodes = [
  {
    text: "Silicon Valley",
    continent: "North America",
    url: "the-united-states-vps",
    value: "1",
    tab: "LightNode",
    countryImg: {
      src: "/_next/static/media/3.2a9d9cea.svg",
      height: 200,
      width: 301,
    },
    countryImgCode: "us",
    banner: {
      src: "/_next/static/media/SiliconValley.d840890a.jpg",
      height: 501,
      width: 1921,
      blurDataURL:
        "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAoKCgoKCgsMDAsPEA4QDxYUExMUFiIYGhgaGCIzICUgICUgMy03LCksNy1RQDg4QFFeT0pPXnFlZXGPiI+7u/sBCgoKCgoKCwwMCw8QDhAPFhQTExQWIhgaGBoYIjMgJSAgJSAzLTcsKSw3LVFAODhAUV5PSk9ecWVlcY+Ij7u7+//CABEIAAIACAMBIgACEQEDEQH/xAAoAAEBAAAAAAAAAAAAAAAAAAAABAEBAQAAAAAAAAAAAAAAAAAAAgP/2gAMAwEAAhADEAAAAIga/wD/xAAZEAADAQEBAAAAAAAAAAAAAAABAgMEAFH/2gAIAQEAAT8A16NCTqUtRT6GI7//xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oACAECAQE/AH//xAAWEQADAAAAAAAAAAAAAAAAAAAAAUH/2gAIAQMBAT8AiP/Z",
      blurWidth: 8,
      blurHeight: 2,
    },
    position: {
      top: 208,
      left: 134,
    },
    regionCode: "us-siliconvalley-1",
    tagLink: "the-united-states-vps",
  },
  {
    text: "Washington",
    continent: "North America",
    url: "washington-vps",
    value: "2",
    tab: "LightNode",
    countryImgCode: "us",
    banner: {
      src: "/_next/static/media/washington.292858dc.jpg",
      height: 501,
      width: 1921,
      blurDataURL:
        "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAoKCgoKCgsMDAsPEA4QDxYUExMUFiIYGhgaGCIzICUgICUgMy03LCksNy1RQDg4QFFeT0pPXnFlZXGPiI+7u/sBCgoKCgoKCwwMCw8QDhAPFhQTExQWIhgaGBoYIjMgJSAgJSAzLTcsKSw3LVFAODhAUV5PSk9ecWVlcY+Ij7u7+//CABEIAAIACAMBIgACEQEDEQH/xAAoAAEBAAAAAAAAAAAAAAAAAAAAAgEBAQAAAAAAAAAAAAAAAAAAAwT/2gAMAwEAAhADEAAAAIDTf//EABsQAAICAwEAAAAAAAAAAAAAAAECAwQABREh/9oACAEBAAE/ALlmyumikWeQObUoLBj3nuf/xAAWEQADAAAAAAAAAAAAAAAAAAAAATH/2gAIAQIBAT8AdP/EABYRAAMAAAAAAAAAAAAAAAAAAAABQf/aAAgBAwEBPwCI/9k=",
      blurWidth: 8,
      blurHeight: 2,
    },
    position: {
      top: 194,
      left: 256,
    },
    regionCode: "us-washington-1",
    tagLink: "the-united-states-vps",
  },
  {
    text: "Frankfurt",
    continent: "Europe",
    url: "germany-vps",
    value: "3",
    tab: "LightNode",
    countryImg: {
      src: "/_next/static/media/9.5e39db80.svg",
      height: 23,
      width: 35,
    },
    countryImgCode: "de",
    banner: {
      src: "/_next/static/media/frankfurt.d16adc9b.jpg",
      height: 501,
      width: 1921,
      blurDataURL:
        "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAoKCgoKCgsMDAsPEA4QDxYUExMUFiIYGhgaGCIzICUgICUgMy03LCksNy1RQDg4QFFeT0pPXnFlZXGPiI+7u/sBCgoKCgoKCwwMCw8QDhAPFhQTExQWIhgaGBoYIjMgJSAgJSAzLTcsKSw3LVFAODhAUV5PSk9ecWVlcY+Ij7u7+//CABEIAAIACAMBIgACEQEDEQH/xAAnAAEBAAAAAAAAAAAAAAAAAAAAAwEBAAAAAAAAAAAAAAAAAAAAAv/aAAwDAQACEAMQAAAAiEf/xAAcEAABAwUAAAAAAAAAAAAAAAACAAETAzEzQmH/2gAIAQEAAT8Anrz5juWz8X//xAAVEQEBAAAAAAAAAAAAAAAAAAAAAf/aAAgBAgEBPwCP/8QAFREBAQAAAAAAAAAAAAAAAAAAAAH/2gAIAQMBAT8Ar//Z",
      blurWidth: 8,
      blurHeight: 2,
    },
    position: {
      top: 162,
      left: 512,
    },
    regionCode: "ger-frankfurt-1",
    tagLink: "germany-vps",
  },
  {
    text: "Istanbul",
    continent: "Asia",
    url: "turkey-vps",
    value: "4",
    tab: "LightNode",
    countryImg: {
      src: "/_next/static/media/2.ad7e6b61.svg",
      height: 23,
      width: 35,
    },
    countryImgCode: "tr",
    banner: {
      src: "/_next/static/media/istanbul.cef5f015.jpg",
      height: 501,
      width: 1921,
      blurDataURL:
        "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAoKCgoKCgsMDAsPEA4QDxYUExMUFiIYGhgaGCIzICUgICUgMy03LCksNy1RQDg4QFFeT0pPXnFlZXGPiI+7u/sBCgoKCgoKCwwMCw8QDhAPFhQTExQWIhgaGBoYIjMgJSAgJSAzLTcsKSw3LVFAODhAUV5PSk9ecWVlcY+Ij7u7+//CABEIAAIACAMBIgACEQEDEQH/xAAnAAEBAAAAAAAAAAAAAAAAAAAABQEBAAAAAAAAAAAAAAAAAAAAAf/aAAwDAQACEAMQAAAAqAf/xAAZEAACAwEAAAAAAAAAAAAAAAABAgADEfH/2gAIAQEAAT8ADMb11ieT/8QAFhEAAwAAAAAAAAAAAAAAAAAAAAIy/9oACAECAQE/AEk//8QAFhEAAwAAAAAAAAAAAAAAAAAAAAMy/9oACAEDAQE/AGUf/9k=",
      blurWidth: 8,
      blurHeight: 2,
    },
    position: {
      top: 200,
      left: 582,
    },
    regionCode: "tur-istanbul-3",
    tagLink: "turkey-vps",
  },
  {
    text: "Riyadh",
    continent: "Asia",
    url: "saudi-arabia-vps",
    value: "5",
    tab: "LightNode",
    countryImg: o,
    countryImgCode: "sa",
    banner: {
      src: "/_next/static/media/riyadh.d4a7d8e2.jpg",
      height: 501,
      width: 1921,
      blurDataURL:
        "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAoKCgoKCgsMDAsPEA4QDxYUExMUFiIYGhgaGCIzICUgICUgMy03LCksNy1RQDg4QFFeT0pPXnFlZXGPiI+7u/sBCgoKCgoKCwwMCw8QDhAPFhQTExQWIhgaGBoYIjMgJSAgJSAzLTcsKSw3LVFAODhAUV5PSk9ecWVlcY+Ij7u7+//CABEIAAIACAMBIgACEQEDEQH/xAAnAAEBAAAAAAAAAAAAAAAAAAAABAEBAAAAAAAAAAAAAAAAAAAABP/aAAwDAQACEAMQAAAAtDw//8QAGRAAAwADAAAAAAAAAAAAAAAAAQIDAAVx/9oACAEBAAE/ANVSjVcM7Hpz/8QAFhEAAwAAAAAAAAAAAAAAAAAAAAIy/9oACAECAQE/AHo//8QAFhEAAwAAAAAAAAAAAAAAAAAAAAIx/9oACAEDAQE/AFh//9k=",
      blurWidth: 8,
      blurHeight: 2,
    },
    position: {
      top: 265,
      left: 618,
    },
    regionCode: "sau-riyadh-1",
    tagLink: "saudi-arabia-vps",
  },
  {
    text: "Dubai",
    continent: "Asia",
    url: "the-united-arab-emirates-vps",
    value: "6",
    tab: "LightNode",
    countryImg: {
      src: "/_next/static/media/Dubai.b5a68375.png",
      height: 28,
      width: 40,
      blurDataURL:
        "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAgAAAAGCAMAAADJ2y/JAAAAV1BMVEX//v///f7//P3w9/Pw9/Lw9vLw9fHWZ2zTZWgcn08bn08LoVDBRjDBRi8AoEgAnkcAnUdYWVhXWVhUWFfDJTHSFSrRBiPSACfRACPAByHMAADLAAAAAABi842HAAAAOElEQVR42h3BBxKAIAwEwFNjiyUQpfP/d8Kwi/C8xogI4n3xyczIx7asRISyz5g6+P+zVlXhUh0aP38Cr1vR4poAAAAASUVORK5CYII=",
      blurWidth: 8,
      blurHeight: 6,
    },
    countryImgCode: "ae",
    banner: {
      src: "/_next/static/media/DUbai.05112376.jpg",
      height: 501,
      width: 1921,
      blurDataURL:
        "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAoKCgoKCgsMDAsPEA4QDxYUExMUFiIYGhgaGCIzICUgICUgMy03LCksNy1RQDg4QFFeT0pPXnFlZXGPiI+7u/sBCgoKCgoKCwwMCw8QDhAPFhQTExQWIhgaGBoYIjMgJSAgJSAzLTcsKSw3LVFAODhAUV5PSk9ecWVlcY+Ij7u7+//CABEIAAIACAMBIgACEQEDEQH/xAAnAAEBAAAAAAAAAAAAAAAAAAAABgEBAAAAAAAAAAAAAAAAAAAABP/aAAwDAQACEAMQAAAAlw4//8QAHBAAAQMFAAAAAAAAAAAAAAAAAwABAgQTIzFC/9oACAEBAAE/AAU4LI8I9R5Zf//EABYRAAMAAAAAAAAAAAAAAAAAAAABQf/aAAgBAgEBPwCI/8QAFhEAAwAAAAAAAAAAAAAAAAAAAAFB/9oACAEDAQE/AKz/2Q==",
      blurWidth: 8,
      blurHeight: 2,
    },
    position: {
      top: 248,
      left: 634,
    },
    regionCode: "uae-dubai-1",
    tagLink: "the-united-arab-emirates-vps",
  },
  {
    text: "Bangkok",
    continent: "Asia",
    url: "thailand-vps",
    value: "7",
    tab: "LightNode",
    countryImg: {
      src: "/_next/static/media/1.9e712141.svg",
      height: 23,
      width: 35,
    },
    countryImgCode: "th",
    banner: {
      src: "/_next/static/media/bangkok.b5f4afd7.jpg",
      height: 501,
      width: 1921,
      blurDataURL:
        "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAoKCgoKCgsMDAsPEA4QDxYUExMUFiIYGhgaGCIzICUgICUgMy03LCksNy1RQDg4QFFeT0pPXnFlZXGPiI+7u/sBCgoKCgoKCwwMCw8QDhAPFhQTExQWIhgaGBoYIjMgJSAgJSAzLTcsKSw3LVFAODhAUV5PSk9ecWVlcY+Ij7u7+//CABEIAAIACAMBIgACEQEDEQH/xAAnAAEBAAAAAAAAAAAAAAAAAAAABQEBAAAAAAAAAAAAAAAAAAAAA//aAAwDAQACEAMQAAAAogF//8QAGxAAAgEFAAAAAAAAAAAAAAAAAQMTAAIRFEH/2gAIAQEAAT8AY1usDJdmQdr/xAAWEQADAAAAAAAAAAAAAAAAAAAAUXH/2gAIAQIBAT8AUP/EABcRAAMBAAAAAAAAAAAAAAAAAAABQnL/2gAIAQMBAT8AVaP/2Q==",
      blurWidth: 8,
      blurHeight: 2,
    },
    position: {
      top: 275,
      left: 775,
    },
    regionCode: "tha-bangkok-1",
    tagLink: "thailand-vps",
  },
  {
    text: "Hanoi",
    continent: "Asia",
    url: "hanoi-vps",
    value: "8",
    tab: "LightNode",
    countryImg: a,
    countryImgCode: "vn",
    banner: {
      src: "/_next/static/media/hanoi.bf3f8c5d.jpg",
      height: 501,
      width: 1921,
      blurDataURL:
        "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAoKCgoKCgsMDAsPEA4QDxYUExMUFiIYGhgaGCIzICUgICUgMy03LCksNy1RQDg4QFFeT0pPXnFlZXGPiI+7u/sBCgoKCgoKCwwMCw8QDhAPFhQTExQWIhgaGBoYIjMgJSAgJSAzLTcsKSw3LVFAODhAUV5PSk9ecWVlcY+Ij7u7+//CABEIAAIACAMBIgACEQEDEQH/xAAoAAEBAAAAAAAAAAAAAAAAAAAAAgEBAQAAAAAAAAAAAAAAAAAAAwT/2gAMAwEAAhADEAAAALBV/wD/xAAcEAABAwUAAAAAAAAAAAAAAAADAAIEAREjQWL/2gAIAQEAAT8AlEI2EKz3UwC3yv/EABYRAAMAAAAAAAAAAAAAAAAAAAADMv/aAAgBAgEBPwBMn//EABcRAAMBAAAAAAAAAAAAAAAAAAABAzH/2gAIAQMBAT8ArqP/2Q==",
      blurWidth: 8,
      blurHeight: 2,
    },
    position: {
      top: 258,
      left: 786,
    },
    regionCode: "vn-henei-1",
    tagLink: "vietnam-vps",
  },
  {
    text: "Phnom Penh",
    continent: "Asia",
    url: "cambodia-vps",
    value: "9",
    tab: "LightNode",
    countryImg: {
      src: "/_next/static/media/4.463565a7.svg",
      height: 23,
      width: 35,
    },
    countryImgCode: "kh",
    banner: {
      src: "/_next/static/media/PhnomPenh.571f677d.jpg",
      height: 501,
      width: 1921,
      blurDataURL:
        "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAoKCgoKCgsMDAsPEA4QDxYUExMUFiIYGhgaGCIzICUgICUgMy03LCksNy1RQDg4QFFeT0pPXnFlZXGPiI+7u/sBCgoKCgoKCwwMCw8QDhAPFhQTExQWIhgaGBoYIjMgJSAgJSAzLTcsKSw3LVFAODhAUV5PSk9ecWVlcY+Ij7u7+//CABEIAAIACAMBIgACEQEDEQH/xAAnAAEBAAAAAAAAAAAAAAAAAAAABgEBAAAAAAAAAAAAAAAAAAAAAv/aAAwDAQACEAMQAAAAowx//8QAGRABAAIDAAAAAAAAAAAAAAAAAQACAxEj/9oACAEBAAE/AMlrVXSnMn//xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oACAECAQE/AH//xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oACAEDAQE/AH//2Q==",
      blurWidth: 8,
      blurHeight: 2,
    },
    position: {
      top: 285,
      left: 786,
    },
    regionCode: "khn-phnompenh-1",
    tagLink: "cambodia-vps",
  },
  {
    text: "Ho Chi Minh",
    continent: "Asia",
    url: "vietnam-vps",
    value: "10",
    tab: "LightNode",
    countryImg: a,
    countryImgCode: "vn",
    banner: {
      src: "/_next/static/media/hochiminhcity.0d7a1fa0.jpg",
      height: 500,
      width: 1920,
      blurDataURL:
        "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAoKCgoKCgsMDAsPEA4QDxYUExMUFiIYGhgaGCIzICUgICUgMy03LCksNy1RQDg4QFFeT0pPXnFlZXGPiI+7u/sBCgoKCgoKCwwMCw8QDhAPFhQTExQWIhgaGBoYIjMgJSAgJSAzLTcsKSw3LVFAODhAUV5PSk9ecWVlcY+Ij7u7+//CABEIAAIACAMBIgACEQEDEQH/xAAoAAEBAAAAAAAAAAAAAAAAAAAAAwEBAQAAAAAAAAAAAAAAAAAAAgP/2gAMAwEAAhADEAAAAIg0/8QAHRAAAAUFAAAAAAAAAAAAAAAAAAECBBEDEhRSYf/aAAgBAQABPwBTpzCzyKs37n0f/8QAFREBAQAAAAAAAAAAAAAAAAAAAAH/2gAIAQIBAT8Ar//EABYRAAMAAAAAAAAAAAAAAAAAAAACMf/aAAgBAwEBPwBqf//Z",
      blurWidth: 8,
      blurHeight: 2,
    },
    position: {
      top: 281,
      left: 799,
    },
    regionCode: "vn-hochiminh-1",
    tagLink: "vietnam-vps",
  },
  {
    text: "Hong Kong",
    continent: "Asia",
    url: "hong-kong-vps",
    value: "11",
    tab: "LightNode",
    countryImg: r,
    countryImgCode: "cn",
    banner: {
      src: "/_next/static/media/hongkong.1d9e7ffc.jpg",
      height: 501,
      width: 1921,
      blurDataURL:
        "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAoKCgoKCgsMDAsPEA4QDxYUExMUFiIYGhgaGCIzICUgICUgMy03LCksNy1RQDg4QFFeT0pPXnFlZXGPiI+7u/sBCgoKCgoKCwwMCw8QDhAPFhQTExQWIhgaGBoYIjMgJSAgJSAzLTcsKSw3LVFAODhAUV5PSk9ecWVlcY+Ij7u7+//CABEIAAIACAMBIgACEQEDEQH/xAAnAAEBAAAAAAAAAAAAAAAAAAAABgEBAAAAAAAAAAAAAAAAAAAABP/aAAwDAQACEAMQAAAAoAov/8QAGxAAAgEFAAAAAAAAAAAAAAAAAhEBABIUMWH/2gAIAQEAAT8AIzyxi6U9Plf/xAAWEQADAAAAAAAAAAAAAAAAAAAAAjH/2gAIAQIBAT8ASH//xAAWEQADAAAAAAAAAAAAAAAAAAAAAzH/2gAIAQMBAT8AZT//2Q==",
      blurWidth: 8,
      blurHeight: 2,
    },
    position: {
      top: 250,
      left: 812,
    },
    regionCode: "cn-hongkong-3-bgp",
    oldRegionCode: "cn-hongkong-3",
    lineType: [
      {
        line: "BGP",
        regionCode: "cn-hongkong-3-bgp",
      },
    ],
    tagLink: "hong-kong-vps",
  },
  {
    text: "Taipei",
    continent: "Asia",
    url: "taiwan-vps",
    value: "12",
    tab: "LightNode",
    countryImg: r,
    countryImgCode: "cn",
    banner: {
      src: "/_next/static/media/taipeichina.20417877.jpg",
      height: 501,
      width: 1921,
      blurDataURL:
        "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAoKCgoKCgsMDAsPEA4QDxYUExMUFiIYGhgaGCIzICUgICUgMy03LCksNy1RQDg4QFFeT0pPXnFlZXGPiI+7u/sBCgoKCgoKCwwMCw8QDhAPFhQTExQWIhgaGBoYIjMgJSAgJSAzLTcsKSw3LVFAODhAUV5PSk9ecWVlcY+Ij7u7+//CABEIAAIACAMBIgACEQEDEQH/xAAoAAEBAAAAAAAAAAAAAAAAAAAABQEBAQAAAAAAAAAAAAAAAAAABAX/2gAMAwEAAhADEAAAAKgfM//EABkQAAIDAQAAAAAAAAAAAAAAAAECABQhMv/aAAgBAQABPwBGagNPE//EABYRAAMAAAAAAAAAAAAAAAAAAAABQf/aAAgBAgEBPwCI/8QAFxEAAwEAAAAAAAAAAAAAAAAAAAJBcf/aAAgBAwEBPwCtp//Z",
      blurWidth: 8,
      blurHeight: 2,
    },
    position: {
      top: 243,
      left: 836,
    },
    regionCode: "cn-taiwan-2",
    tagLink: "taiwan-vps",
  },
  {
    text: "Seoul",
    continent: "Asia",
    url: "korea-vps",
    value: "13",
    tab: "LightNode VU&DO",
    countryImg: {
      src: "/_next/static/media/7.4e0429ea.svg",
      height: 23,
      width: 35,
    },
    countryImgCode: "kr",
    banner: {
      src: "/_next/static/media/seoul.12f6c153.jpg",
      height: 501,
      width: 1921,
      blurDataURL:
        "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAoKCgoKCgsMDAsPEA4QDxYUExMUFiIYGhgaGCIzICUgICUgMy03LCksNy1RQDg4QFFeT0pPXnFlZXGPiI+7u/sBCgoKCgoKCwwMCw8QDhAPFhQTExQWIhgaGBoYIjMgJSAgJSAzLTcsKSw3LVFAODhAUV5PSk9ecWVlcY+Ij7u7+//CABEIAAIACAMBIgACEQEDEQH/xAAoAAEBAAAAAAAAAAAAAAAAAAAABQEBAQAAAAAAAAAAAAAAAAAAAwT/2gAMAwEAAhADEAAAAKIsP//EABgQAAIDAAAAAAAAAAAAAAAAAAACBFKR/9oACAEBAAE/AJLvdtP/xAAWEQADAAAAAAAAAAAAAAAAAAAAAzL/2gAIAQIBAT8AVJ//xAAWEQADAAAAAAAAAAAAAAAAAAAAAjL/2gAIAQMBAT8Aej//2Q==",
      blurWidth: 8,
      blurHeight: 2,
    },
    position: {
      top: 209,
      left: 860,
    },
    regionCode: "kr-seoul-1",
    tagLink: "korea-vps",
  },
  {
    text: "Johannesburg",
    continent: "Africa",
    url: "south-africa-vps",
    value: "14",
    tab: "LightNode",
    countryImg: {
      src: "/_next/static/media/13.87bdf3d8.svg",
      height: 23,
      width: 35,
    },
    countryImgCode: "za",
    banner: {
      src: "/_next/static/media/Johannesburg.d1737175.jpg",
      height: 501,
      width: 1921,
      blurDataURL:
        "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAoKCgoKCgsMDAsPEA4QDxYUExMUFiIYGhgaGCIzICUgICUgMy03LCksNy1RQDg4QFFeT0pPXnFlZXGPiI+7u/sBCgoKCgoKCwwMCw8QDhAPFhQTExQWIhgaGBoYIjMgJSAgJSAzLTcsKSw3LVFAODhAUV5PSk9ecWVlcY+Ij7u7+//CABEIAAIACAMBIgACEQEDEQH/xAAnAAEBAAAAAAAAAAAAAAAAAAAABQEBAAAAAAAAAAAAAAAAAAAAAv/aAAwDAQACEAMQAAAAuhH/xAAaEAEAAQUAAAAAAAAAAAAAAAADAAISIjFR/9oACAEBAAE/ACRLTzq12f/EABURAQEAAAAAAAAAAAAAAAAAAAAB/9oACAECAQE/AK//xAAVEQEBAAAAAAAAAAAAAAAAAAAAAf/aAAgBAwEBPwCP/9k=",
      blurWidth: 8,
      blurHeight: 2,
    },
    position: {
      top: 370,
      left: 575,
    },
    regionCode: "sa-johannesburg-1",
    tagLink: "south-africa-vps",
  },
  {
    text: "Singapore",
    continent: "Asia",
    url: "singapore-vps",
    value: "15",
    tab: "LightNode VU&DO",
    countryImg: {
      src: "/_next/static/media/16.0eeae188.svg",
      height: 23,
      width: 35,
    },
    countryImgCode: "sg",
    banner: {
      src: "/_next/static/media/Singapore.2e6b174e.jpg",
      height: 501,
      width: 1920,
      blurDataURL:
        "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAoKCgoKCgsMDAsPEA4QDxYUExMUFiIYGhgaGCIzICUgICUgMy03LCksNy1RQDg4QFFeT0pPXnFlZXGPiI+7u/sBCgoKCgoKCwwMCw8QDhAPFhQTExQWIhgaGBoYIjMgJSAgJSAzLTcsKSw3LVFAODhAUV5PSk9ecWVlcY+Ij7u7+//CABEIAAIACAMBIgACEQEDEQH/xAAoAAEBAAAAAAAAAAAAAAAAAAAAAwEBAQAAAAAAAAAAAAAAAAAAAAP/2gAMAwEAAhADEAAAAJhT/8QAGxABAAICAwAAAAAAAAAAAAAAAQIDBCEAERL/2gAIAQEAAT8AyMbHKYJRWMY9D5NGuf/EABURAQEAAAAAAAAAAAAAAAAAAAAB/9oACAECAQE/AI//xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oACAEDAQE/AH//2Q==",
      blurWidth: 8,
      blurHeight: 2,
    },
    position: {
      top: 324,
      left: 786,
    },
    regionCode: "sgp-singapore-1",
    tagLink: "singapore-vps",
  },
  {
    text: "Manila",
    continent: "Asia",
    value: "16",
    tab: "LightNode",
    url: "philippines-vps",
    countryImg: {
      src: "/_next/static/media/17.af46ce12.svg",
      height: 23,
      width: 35,
    },
    countryImgCode: "ph",
    banner: {
      src: "/_next/static/media/Manila.f061bf4d.jpg",
      height: 501,
      width: 1920,
      blurDataURL:
        "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAoKCgoKCgsMDAsPEA4QDxYUExMUFiIYGhgaGCIzICUgICUgMy03LCksNy1RQDg4QFFeT0pPXnFlZXGPiI+7u/sBCgoKCgoKCwwMCw8QDhAPFhQTExQWIhgaGBoYIjMgJSAgJSAzLTcsKSw3LVFAODhAUV5PSk9ecWVlcY+Ij7u7+//CABEIAAIACAMBIgACEQEDEQH/xAAoAAEBAAAAAAAAAAAAAAAAAAAABAEBAQAAAAAAAAAAAAAAAAAAAwX/2gAMAwEAAhADEAAAAIA1P//EABgQAAMBAQAAAAAAAAAAAAAAAAECAwBx/9oACAEBAAE/AFvdIMFs44x3/8QAFxEBAAMAAAAAAAAAAAAAAAAAAgAxcf/aAAgBAgEBPwA2tn//xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oACAEDAQE/AH//2Q==",
      blurWidth: 8,
      blurHeight: 2,
    },
    position: {
      top: 291,
      left: 851,
    },
    regionCode: "ph-manila-1",
    tagLink: "philippines-vps",
  },
  {
    text: "Dhaka",
    continent: "Asia",
    url: "bangladesh-vps",
    value: "17",
    tab: "LightNode",
    countryImg: {
      src: "/_next/static/media/18.3f329b9b.svg",
      height: 23,
      width: 35,
    },
    countryImgCode: "bd",
    banner: {
      src: "/_next/static/media/Dhaka.1c3fce07.jpg",
      height: 501,
      width: 1920,
      blurDataURL:
        "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAoKCgoKCgsMDAsPEA4QDxYUExMUFiIYGhgaGCIzICUgICUgMy03LCksNy1RQDg4QFFeT0pPXnFlZXGPiI+7u/sBCgoKCgoKCwwMCw8QDhAPFhQTExQWIhgaGBoYIjMgJSAgJSAzLTcsKSw3LVFAODhAUV5PSk9ecWVlcY+Ij7u7+//CABEIAAIACAMBIgACEQEDEQH/xAAoAAEBAAAAAAAAAAAAAAAAAAAABQEBAQAAAAAAAAAAAAAAAAAAAQP/2gAMAwEAAhADEAAAAL4Jf//EABkQAAMAAwAAAAAAAAAAAAAAAAECAwARgv/aAAgBAQABPwBbWZNmrno5/8QAFxEBAAMAAAAAAAAAAAAAAAAAAQAxcf/aAAgBAgEBPwAt2f/EABcRAAMBAAAAAAAAAAAAAAAAAAACQnL/2gAIAQMBAT8AeMn/2Q==",
      blurWidth: 8,
      blurHeight: 2,
    },
    position: {
      top: 242,
      left: 748,
    },
    regionCode: "bg-dhaka-1",
    tagLink: "bangladesh-vps",
  },
  {
    text: "Sao Paulo",
    continent: "South America",
    url: "brazil-vps",
    value: "18",
    tab: "LightNode",
    countryImg: {
      src: "/_next/static/media/19.9db5f477.svg",
      height: 23,
      width: 35,
    },
    countryImgCode: "br",
    banner: {
      src: "/_next/static/media/saopaulo.394f1825.jpg",
      height: 501,
      width: 1920,
      blurDataURL:
        "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAoKCgoKCgsMDAsPEA4QDxYUExMUFiIYGhgaGCIzICUgICUgMy03LCksNy1RQDg4QFFeT0pPXnFlZXGPiI+7u/sBCgoKCgoKCwwMCw8QDhAPFhQTExQWIhgaGBoYIjMgJSAgJSAzLTcsKSw3LVFAODhAUV5PSk9ecWVlcY+Ij7u7+//CABEIAAIACAMBIgACEQEDEQH/xAAoAAEBAAAAAAAAAAAAAAAAAAAABQEBAQAAAAAAAAAAAAAAAAAABQb/2gAMAwEAAhADEAAAALQsxv/EABwQAAICAgMAAAAAAAAAAAAAAAEDBBEAAhIhIv/aAAgBAQABPwBUSIUPuMo8dmV4HVE5/8QAGBEAAgMAAAAAAAAAAAAAAAAAAAIBMXL/2gAIAQIBAT8AW31J/8QAGBEAAgMAAAAAAAAAAAAAAAAAAAECMXH/2gAIAQMBAT8AVRxH/9k=",
      blurWidth: 8,
      blurHeight: 2,
    },
    position: {
      top: 366,
      left: 350,
    },
    regionCode: "br-saopaulo-1",
    tagLink: "brazil-vps",
  },
  {
    text: "Jeddah",
    continent: "Asia",
    url: "jeddah-vps",
    value: "19",
    tab: "LightNode",
    countryImg: o,
    countryImgCode: "sa",
    banner: {
      src: "/_next/static/media/jeddah.5b645cf5.jpg",
      height: 500,
      width: 1920,
      blurDataURL:
        "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAoKCgoKCgsMDAsPEA4QDxYUExMUFiIYGhgaGCIzICUgICUgMy03LCksNy1RQDg4QFFeT0pPXnFlZXGPiI+7u/sBCgoKCgoKCwwMCw8QDhAPFhQTExQWIhgaGBoYIjMgJSAgJSAzLTcsKSw3LVFAODhAUV5PSk9ecWVlcY+Ij7u7+//CABEIAAIACAMBIgACEQEDEQH/xAAnAAEBAAAAAAAAAAAAAAAAAAAABAEBAAAAAAAAAAAAAAAAAAAABP/aAAwDAQACEAMQAAAAsCi//8QAGhABAQACAwAAAAAAAAAAAAAAAQMAAgQSQf/aAAgBAQABPwC9anDEpsPd9z//xAAXEQEAAwAAAAAAAAAAAAAAAAABADJx/9oACAECAQE/AGzs/8QAGBEAAgMAAAAAAAAAAAAAAAAAAAECMXH/2gAIAQMBAT8AVRw//9k=",
      blurWidth: 8,
      blurHeight: 2,
    },
    position: {
      top: 263,
      left: 618,
    },
    regionCode: "sau-jeddah-1",
    tagLink: "saudi-arabia-vps",
  },
  {
    text: "Tokyo",
    continent: "Asia",
    url: "japan-vps",
    value: "20",
    tab: "LightNode",
    countryImg: i,
    countryImgCode: "jp",
    banner: {
      src: "/_next/static/media/Tokyo.3808ecc7.jpg",
      height: 501,
      width: 1921,
      blurDataURL:
        "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAoKCgoKCgsMDAsPEA4QDxYUExMUFiIYGhgaGCIzICUgICUgMy03LCksNy1RQDg4QFFeT0pPXnFlZXGPiI+7u/sBCgoKCgoKCwwMCw8QDhAPFhQTExQWIhgaGBoYIjMgJSAgJSAzLTcsKSw3LVFAODhAUV5PSk9ecWVlcY+Ij7u7+//CABEIAAIACAMBIgACEQEDEQH/xAAoAAEBAAAAAAAAAAAAAAAAAAAABgEBAQAAAAAAAAAAAAAAAAAAAwX/2gAMAwEAAhADEAAAAJgUg//EABoQAAICAwAAAAAAAAAAAAAAAAEDAAIRYZH/2gAIAQEAAT8AClGpyuvNT//EABURAQEAAAAAAAAAAAAAAAAAAAAC/9oACAECAQE/AJf/xAAVEQEBAAAAAAAAAAAAAAAAAAAAAf/aAAgBAwEBPwCv/9k=",
      blurWidth: 8,
      blurHeight: 2,
    },
    position: {
      top: 225,
      left: 894,
    },
    regionCode: "jp-tokyo-1",
    tagLink: "japan-vps",
  },
  {
    text: "Cairo",
    continent: "Africa",
    url: "egypt-vps",
    value: "21",
    tab: "LightNode",
    countryImg: {
      src: "/_next/static/media/Cairo.2615301a.png",
      height: 28,
      width: 40,
      blurDataURL:
        "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAgAAAAGCAMAAADJ2y/JAAAAUVBMVEX4+/73+vz+9fj1+Pj19/f19/b98/T88/Pv38zt3cfg2rrd1a7QP1HQPk/OLzvOLjvOLTnNLThDQ0PKABrKABlBPj9APj5APT7KAAjKAAYAAABgru52AAAAN0lEQVR42i3ByQGAIAwEwBU03lFgCUf/hfJhBiRbTSRU/+cN+kHEnYfbBX5d7gubh5UcYzFDnwZIWALoX3Uf8QAAAABJRU5ErkJggg==",
      blurWidth: 8,
      blurHeight: 6,
    },
    countryImgCode: "eg",
    banner: {
      src: "/_next/static/media/Cairo.0ca1c4be.jpg",
      height: 500,
      width: 1920,
      blurDataURL:
        "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAoKCgoKCgsMDAsPEA4QDxYUExMUFiIYGhgaGCIzICUgICUgMy03LCksNy1RQDg4QFFeT0pPXnFlZXGPiI+7u/sBCgoKCgoKCwwMCw8QDhAPFhQTExQWIhgaGBoYIjMgJSAgJSAzLTcsKSw3LVFAODhAUV5PSk9ecWVlcY+Ij7u7+//CABEIAAIACAMBIgACEQEDEQH/xAAoAAEBAAAAAAAAAAAAAAAAAAAABgEBAQAAAAAAAAAAAAAAAAAAAQL/2gAMAwEAAhADEAAAAKkNf//EABkQAAMAAwAAAAAAAAAAAAAAAAECEQBCwf/aAAgBAQABPwCkq9O3M//EABcRAAMBAAAAAAAAAAAAAAAAAAACQXH/2gAIAQIBAT8Araf/xAAWEQADAAAAAAAAAAAAAAAAAAAAAUH/2gAIAQMBAT8AiP/Z",
      blurWidth: 8,
      blurHeight: 2,
    },
    position: {
      top: 243,
      left: 570,
    },
    regionCode: "eg-cairo-1",
    tagLink: "egypt-vps",
  },
  {
    text: "Bahrain",
    continent: "Asia",
    url: "bahrain-vps",
    value: "22",
    tab: "LightNode",
    countryImg: {
      src: "/_next/static/media/Bahrain.6e0dfbc3.png",
      height: 28,
      width: 40,
      blurDataURL:
        "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAgAAAAGCAMAAADJ2y/JAAAARVBMVEX////+///+/v79/Pzrw8bqwsXqvsHqvsDpvb/pvL/PFCjPEyfOEyjODSXPDCXOCSTPCCTNCSTPCCPOCCTOAADNAALNAAAc2Ux0AAAAMklEQVR42g3GxwEAIAgEMOy9gbL/qF5eIWeC9nEOWcq3TmYkap1rIQkRQQqyN+JfGyIfNj8CGMdtwaEAAAAASUVORK5CYII=",
      blurWidth: 8,
      blurHeight: 6,
    },
    countryImgCode: "bh",
    banner: {
      src: "/_next/static/media/Bahrain.c8cbb449.jpg",
      height: 500,
      width: 1920,
      blurDataURL:
        "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAoKCgoKCgsMDAsPEA4QDxYUExMUFiIYGhgaGCIzICUgICUgMy03LCksNy1RQDg4QFFeT0pPXnFlZXGPiI+7u/sBCgoKCgoKCwwMCw8QDhAPFhQTExQWIhgaGBoYIjMgJSAgJSAzLTcsKSw3LVFAODhAUV5PSk9ecWVlcY+Ij7u7+//CABEIAAIACAMBIgACEQEDEQH/xAAoAAEBAAAAAAAAAAAAAAAAAAAAAQEBAQAAAAAAAAAAAAAAAAAAAwT/2gAMAwEAAhADEAAAAKGq/8QAGRABAQADAQAAAAAAAAAAAAAAAQIAAxEh/9oACAEBAAE/ALmWtIyer3P/xAAXEQEAAwAAAAAAAAAAAAAAAAABADGB/9oACAECAQE/ACtZ/8QAGBEAAgMAAAAAAAAAAAAAAAAAAAECMYH/2gAIAQMBAT8AleI//9k=",
      blurWidth: 8,
      blurHeight: 2,
    },
    position: {
      top: 246,
      left: 592,
    },
    regionCode: "bh-askar-1",
    tagLink: "bahrain-vps",
  },
  {
    text: "Sofia",
    continent: "Europe",
    url: "bulgaria-vps",
    value: "23",
    tab: "LightNode",
    countryImg: {
      src: "/_next/static/media/Sofia.bd30fe15.png",
      height: 28,
      width: 40,
      blurDataURL:
        "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAgAAAAGBAMAAAAMK8LIAAAALVBMVEX////z+Pfz+Pby9/Uwn34wn30wnn0XjWYXjGbNOCXMOCXZIAvZHwvZHArYGQnHAWndAAAAI0lEQVR42mMAA0MlJSWGlNDQUIb28vJyhpUzZ85keLtn924AWIoJepWtfT4AAAAASUVORK5CYII=",
      blurWidth: 8,
      blurHeight: 6,
    },
    countryImgCode: "bg",
    banner: {
      src: "/_next/static/media/Sofia.8b76e2bc.jpg",
      height: 500,
      width: 1920,
      blurDataURL:
        "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAoKCgoKCgsMDAsPEA4QDxYUExMUFiIYGhgaGCIzICUgICUgMy03LCksNy1RQDg4QFFeT0pPXnFlZXGPiI+7u/sBCgoKCgoKCwwMCw8QDhAPFhQTExQWIhgaGBoYIjMgJSAgJSAzLTcsKSw3LVFAODhAUV5PSk9ecWVlcY+Ij7u7+//CABEIAAIACAMBIgACEQEDEQH/xAAnAAEBAAAAAAAAAAAAAAAAAAAAAgEBAAAAAAAAAAAAAAAAAAAAA//aAAwDAQACEAMQAAAAsIP/xAAdEAABAgcAAAAAAAAAAAAAAAABAAMCBBESI1FS/9oACAEBAAE/AIJh821ecOLo7X//xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oACAECAQE/AH//xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oACAEDAQE/AH//2Q==",
      blurWidth: 8,
      blurHeight: 2,
    },
    position: {
      top: 186,
      left: 556,
    },
    regionCode: "bg-sofia-1",
    tagLink: "bulgaria-vps",
  },
  {
    text: "Athens",
    continent: "Europe",
    url: "greece-vps",
    value: "24",
    tab: "LightNode",
    countryImg: {
      src: "/_next/static/media/Athens.18204639.png",
      height: 28,
      width: 40,
      blurDataURL:
        "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAgAAAAGCAIAAABxZ0isAAAAd0lEQVR42mNg1JmyZeclBo0pi5cfXbn2xPLVJ1asASGGQ8dvPnr6dueBq5t3Xty2+9LWXZe2gRFDZOryg0dvBiYsW7L69KoN51asPwtBDOu3nj9/+dGaTedWoyKG7bsvbtx6Dkju2HMJGTGsXHty9brTK9eeQkMA8V5lgzDSJ6EAAAAASUVORK5CYII=",
      blurWidth: 8,
      blurHeight: 6,
    },
    countryImgCode: "gr",
    banner: {
      src: "/_next/static/media/Athens.e7a5d4cf.jpg",
      height: 500,
      width: 1920,
      blurDataURL:
        "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAoKCgoKCgsMDAsPEA4QDxYUExMUFiIYGhgaGCIzICUgICUgMy03LCksNy1RQDg4QFFeT0pPXnFlZXGPiI+7u/sBCgoKCgoKCwwMCw8QDhAPFhQTExQWIhgaGBoYIjMgJSAgJSAzLTcsKSw3LVFAODhAUV5PSk9ecWVlcY+Ij7u7+//CABEIAAIACAMBIgACEQEDEQH/xAAoAAEBAAAAAAAAAAAAAAAAAAAABAEBAQAAAAAAAAAAAAAAAAAAAgP/2gAMAwEAAhADEAAAALhB/wD/xAAaEAACAgMAAAAAAAAAAAAAAAABAwACBDJC/9oACAEBAAE/AMp7y2oLmbV6M//EABYRAAMAAAAAAAAAAAAAAAAAAAADMv/aAAgBAgEBPwBUn//EABYRAAMAAAAAAAAAAAAAAAAAAAADMv/aAAgBAwEBPwBlH//Z",
      blurWidth: 8,
      blurHeight: 2,
    },
    position: {
      top: 207,
      left: 538,
    },
    regionCode: "gr-athens-1",
    tagLink: "greece-vps",
  },
  {
    text: "Kuala Lumpur",
    continent: "Asia",
    url: "malaysia-vps",
    value: "25",
    tab: "LightNode",
    countryImg: {
      src: "/_next/static/media/Lumpur.1b5127c6.png",
      height: 28,
      width: 40,
      blurDataURL:
        "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAgAAAAGCAIAAABxZ0isAAAAiklEQVR42mPQdFwZETuLgXWdlcOah3MXvFq04MVCEGLoqOqMjZ2xZFJqRsLsh4vXvF2z4vWqlUDEkJUzPSJ5eklZm0fYskfrt73bsfX1tq1vtm1lKLGb3hzUm6w0q8F75rM1a99u2vB6w/rXGzcwvFu7/O3qFe/XLQMyXq9eCUcML1esQELLX8EQABwfXH4qsuiaAAAAAElFTkSuQmCC",
      blurWidth: 8,
      blurHeight: 6,
    },
    countryImgCode: "my",
    banner: {
      src: "/_next/static/media/Lumpur.108a87df.jpg",
      height: 499,
      width: 1920,
      blurDataURL:
        "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAoKCgoKCgsMDAsPEA4QDxYUExMUFiIYGhgaGCIzICUgICUgMy03LCksNy1RQDg4QFFeT0pPXnFlZXGPiI+7u/sBCgoKCgoKCwwMCw8QDhAPFhQTExQWIhgaGBoYIjMgJSAgJSAzLTcsKSw3LVFAODhAUV5PSk9ecWVlcY+Ij7u7+//CABEIAAIACAMBIgACEQEDEQH/xAAnAAEBAAAAAAAAAAAAAAAAAAAAAgEBAAAAAAAAAAAAAAAAAAAABf/aAAwDAQACEAMQAAAAoNHf/8QAGhAAAgIDAAAAAAAAAAAAAAAAAgMAARIikf/aAAgBAQABPwC2Hg3cuz//xAAXEQADAQAAAAAAAAAAAAAAAAAAAQIy/9oACAECAQE/AJyj/8QAFhEBAQEAAAAAAAAAAAAAAAAAAQAy/9oACAEDAQE/AHTf/9k=",
      blurWidth: 8,
      blurHeight: 2,
    },
    position: {
      top: 310,
      left: 776,
    },
    regionCode: "my-kualalumpur-1",
    tagLink: "malaysia-vps",
  },
  {
    text: "London",
    continent: "Europe",
    url: "london-vps",
    value: "26",
    tab: "LightNode",
    countryImg: {
      src: "/_next/static/media/London.764c959d.png",
      height: 28,
      width: 40,
      blurDataURL:
        "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAgAAAAGCAIAAABxZ0isAAAAoUlEQVR42gGWAGn/ANqnr8S2wQAYbbN1h7V7jAAAY691iuG9wwBlbY/Ur7nW1NzHoavCj5vFqrfh0dd6lKwAzYSOzHiD35OX1nyC0V9p4Jic0IuUynSBAMp1gc+Kk+GZndFha9V6f9+UmMx3g82EjgB2kqrf0dfHq7jDkp7FnafU1NzWsbpobZAA4b7EsniMAABjtX6Os3OGAA9rwrW/26mx7j5YbKE8ANAAAAAASUVORK5CYII=",
      blurWidth: 8,
      blurHeight: 6,
    },
    countryImgCode: "gb",
    banner: {
      src: "/_next/static/media/london.84dfa53f.jpg",
      height: 500,
      width: 1920,
      blurDataURL:
        "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAoKCgoKCgsMDAsPEA4QDxYUExMUFiIYGhgaGCIzICUgICUgMy03LCksNy1RQDg4QFFeT0pPXnFlZXGPiI+7u/sBCgoKCgoKCwwMCw8QDhAPFhQTExQWIhgaGBoYIjMgJSAgJSAzLTcsKSw3LVFAODhAUV5PSk9ecWVlcY+Ij7u7+//CABEIAAIACAMBIgACEQEDEQH/xAAnAAEBAAAAAAAAAAAAAAAAAAAABQEBAAAAAAAAAAAAAAAAAAAABP/aAAwDAQACEAMQAAAApAL/AP/EABwQAAEEAwEAAAAAAAAAAAAAAAIBAwQRABIxQf/aAAgBAQABPwAJMgIhaPuDV8JU9z//xAAXEQADAQAAAAAAAAAAAAAAAAAAAQIy/9oACAECAQE/AK0z/8QAFxEAAwEAAAAAAAAAAAAAAAAAAAECMf/aAAgBAwEBPwCcR//Z",
      blurWidth: 8,
      blurHeight: 2,
    },
    position: {
      top: 148,
      left: 478,
    },
    regionCode: "gb-london-1",
    tagLink: "london-vps",
  },
  {
    text: "Muscat",
    continent: "Asia",
    url: "oman-vps",
    value: "27",
    tab: "LightNode",
    countryImg: {
      src: "/_next/static/media/Muscat.738bf286.png",
      height: 28,
      width: 40,
      blurDataURL:
        "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAgAAAAGCAMAAADJ2y/JAAAAWlBMVEXdREbZGhv////jgIDgYWLfYGHGQBfaGxzbGh7bFRoAgwAAgADfABv89vb89PT79PTkh4fifX3dPEDIPxnbKS0/fg49fg4sgA3bGB3aEhPXFgDYFQDfABzaAADNmVBNAAAADXRSTlP7+/39/f39/f39/f39Nj0m7AAAADVJREFUeNoVwYUBwCAMBMCvS1qc4PuvCdwB+7ZOOJT+pRQCd3NmwhNTLgOuaoNnZizf+RIRdUDqAr8XcQmmAAAAAElFTkSuQmCC",
      blurWidth: 8,
      blurHeight: 6,
    },
    countryImgCode: "om",
    banner: {
      src: "/_next/static/media/Muscat.2eb6e373.jpg",
      height: 500,
      width: 1920,
      blurDataURL:
        "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAoKCgoKCgsMDAsPEA4QDxYUExMUFiIYGhgaGCIzICUgICUgMy03LCksNy1RQDg4QFFeT0pPXnFlZXGPiI+7u/sBCgoKCgoKCwwMCw8QDhAPFhQTExQWIhgaGBoYIjMgJSAgJSAzLTcsKSw3LVFAODhAUV5PSk9ecWVlcY+Ij7u7+//CABEIAAIACAMBIgACEQEDEQH/xAAnAAEBAAAAAAAAAAAAAAAAAAAABAEBAAAAAAAAAAAAAAAAAAAAA//aAAwDAQACEAMQAAAAtAP/AP/EABsQAAEEAwAAAAAAAAAAAAAAAAMAAQITERJB/9oACAEBAAE/AAEJUZ95Zol1f//EABURAQEAAAAAAAAAAAAAAAAAAAAB/9oACAECAQE/AI//xAAVEQEBAAAAAAAAAAAAAAAAAAAAAf/aAAgBAwEBPwCv/9k=",
      blurWidth: 8,
      blurHeight: 2,
    },
    position: {
      top: 258,
      left: 650,
    },
    regionCode: "om-muscat-1",
    tagLink: "oman-vps",
  },
  {
    text: "Kuwait City",
    continent: "Asia",
    url: "kuwait-vps",
    value: "28",
    tab: "LightNode",
    countryImg: {
      src: "/_next/static/media/Kuwait.f4460785.png",
      height: 34,
      width: 50,
      blurDataURL:
        "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAgAAAAFCAMAAABPT11nAAAASFBMVEWbtqLfj5KZs6CZs5/cjpHbjZD///9OcFaiR0p8hIYAejUJbzm8FCXTABUAaAAAZwDKAADJAAAAOxppAg0lIB4ACAYKAAQAAADUC9hSAAAACnRSTlP4+Pn5+fn8/f3+sdW2ZgAAADBJREFUeNoVwYcBgCAMBMA3RukQavbfFLhDC77kA0sNXiLCUPdfmGqfj5nRY6oiIhsnewHBSoQc4wAAAABJRU5ErkJggg==",
      blurWidth: 8,
      blurHeight: 5,
    },
    countryImgCode: "kw",
    banner: {
      src: "/_next/static/media/Kuwait.461bdd7b.jpg",
      height: 500,
      width: 1920,
      blurDataURL:
        "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAoKCgoKCgsMDAsPEA4QDxYUExMUFiIYGhgaGCIzICUgICUgMy03LCksNy1RQDg4QFFeT0pPXnFlZXGPiI+7u/sBCgoKCgoKCwwMCw8QDhAPFhQTExQWIhgaGBoYIjMgJSAgJSAzLTcsKSw3LVFAODhAUV5PSk9ecWVlcY+Ij7u7+//CABEIAAIACAMBIgACEQEDEQH/xAAoAAEBAAAAAAAAAAAAAAAAAAAABQEBAQAAAAAAAAAAAAAAAAAAAgT/2gAMAwEAAhADEAAAAJ4c3//EABsQAAIBBQAAAAAAAAAAAAAAAAEDEQACBRIh/9oACAEBAAE/AHgW4tWoiUTyv//EABcRAAMBAAAAAAAAAAAAAAAAAAABAzH/2gAIAQIBAT8AljP/xAAYEQACAwAAAAAAAAAAAAAAAAAAAgQycf/aAAgBAwEBPwCTZcP/2Q==",
      blurWidth: 8,
      blurHeight: 2,
    },
    position: {
      top: 250,
      left: 620,
    },
    regionCode: "kw-kuwait-1",
    tagLink: "kuwait-vps",
  },
  {
    text: "Marseille",
    continent: "Europe",
    url: "marseille-vps",
    value: "29",
    tab: "LightNode",
    countryImg: {
      src: "/_next/static/media/Marseille.b6efd0e6.png",
      height: 34,
      width: 50,
      blurDataURL:
        "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAgAAAAFBAMAAACKv7BmAAAAJ1BMVEX////+///zmZ3zmZyUmL7uNkTuNUPtAADsAAAgM5kgMpgAAIwAAItNxutVAAAAHElEQVR42mOY7SBUyrDGQbiNYTWQgLBmOwiVAgBdJwdTpy52qgAAAABJRU5ErkJggg==",
      blurWidth: 8,
      blurHeight: 5,
    },
    countryImgCode: "fr",
    banner: {
      src: "/_next/static/media/Marseille.a6eaaac2.jpg",
      height: 500,
      width: 1920,
      blurDataURL:
        "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAoKCgoKCgsMDAsPEA4QDxYUExMUFiIYGhgaGCIzICUgICUgMy03LCksNy1RQDg4QFFeT0pPXnFlZXGPiI+7u/sBCgoKCgoKCwwMCw8QDhAPFhQTExQWIhgaGBoYIjMgJSAgJSAzLTcsKSw3LVFAODhAUV5PSk9ecWVlcY+Ij7u7+//CABEIAAIACAMBIgACEQEDEQH/xAAnAAEBAAAAAAAAAAAAAAAAAAAABQEBAAAAAAAAAAAAAAAAAAAABP/aAAwDAQACEAMQAAAAsBQf/8QAGRABAAIDAAAAAAAAAAAAAAAAAgABISIj/9oACAEBAAE/AGly2vLn/8QAFhEAAwAAAAAAAAAAAAAAAAAAAAEx/9oACAECAQE/AHT/xAAWEQADAAAAAAAAAAAAAAAAAAAAAjH/2gAIAQMBAT8AWH//2Q==",
      blurWidth: 8,
      blurHeight: 2,
    },
    position: {
      top: 200,
      left: 496,
    },
    regionCode: "fr-marseille-1",
    tagLink: "france-vps",
  },
  {
    text: "Karachi",
    continent: "Asia",
    url: "pakistan-vps",
    value: "30",
    tab: "LightNode",
    countryImg: {
      src: "/_next/static/media/Karachi.6445be16.png",
      height: 34,
      width: 50,
      blurDataURL:
        "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAgAAAAFCAIAAAD38zoCAAAAeklEQVR42mP4////tlPbGLIZ9Fv1Y6fFMtQwMNQzMDcwMwAltp/ezpDIMGnzpMTpiept6lqtWgx1DCCJHWd2MEQxrDu6rnZZLUMRg1STFEM9AwPUqAwGv36/ZfuXVS+tVm5VZqhjgEnkMTDUMzBUMth32bM3sDPUMwAAWlAzo3PFLhwAAAAASUVORK5CYII=",
      blurWidth: 8,
      blurHeight: 5,
    },
    countryImgCode: "pk",
    banner: {
      src: "/_next/static/media/Karachi.fbbebbc6.jpg",
      height: 500,
      width: 1920,
      blurDataURL:
        "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAoKCgoKCgsMDAsPEA4QDxYUExMUFiIYGhgaGCIzICUgICUgMy03LCksNy1RQDg4QFFeT0pPXnFlZXGPiI+7u/sBCgoKCgoKCwwMCw8QDhAPFhQTExQWIhgaGBoYIjMgJSAgJSAzLTcsKSw3LVFAODhAUV5PSk9ecWVlcY+Ij7u7+//CABEIAAIACAMBIgACEQEDEQH/xAAnAAEBAAAAAAAAAAAAAAAAAAAABwEBAAAAAAAAAAAAAAAAAAAAAf/aAAwDAQACEAMQAAAAp4H/xAAdEAABAgcAAAAAAAAAAAAAAAACERIAAQMEFSFx/9oACAEBAAE/AKxnkLWTyRpaXkf/xAAVEQEBAAAAAAAAAAAAAAAAAAAAAf/aAAgBAgEBPwCP/8QAFREBAQAAAAAAAAAAAAAAAAAAAAH/2gAIAQMBAT8Ar//Z",
      blurWidth: 8,
      blurHeight: 2,
    },
    position: {
      top: 240,
      left: 688,
    },
    regionCode: "pk-karachi-1",
    tagLink: "pakistan-vps",
  },
  {
    text: "kathmandu",
    continent: "Asia",
    url: "nepal-vps",
    value: "31",
    tab: "LightNode",
    countryImg: {
      src: "/_next/static/media/Nepal.9fc2355a.png",
      height: 34,
      width: 50,
      blurDataURL:
        "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAgAAAAFCAYAAAB4ka1VAAAAgklEQVR42mMAgRqPMsX5DJrbdBkYNBmgYIpsMCMDEpC52jnh/9Wuif8WM0jMSfItUwAJrpDxhCgSYWCQOV9Y9W9fVfvNWQz6NSXG6XEMtk2sKCY823fo54s9+/9PZmDIg4saFkJMcGBQlT2cUvT9QmLW/30Mev97taImgcT/MzAwAgAbiimGp1Ou7QAAAABJRU5ErkJggg==",
      blurWidth: 8,
      blurHeight: 5,
    },
    countryImgCode: "np",
    banner: {
      src: "/_next/static/media/Nepal.7c07bb8c.jpg",
      height: 501,
      width: 1920,
      blurDataURL:
        "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAoKCgoKCgsMDAsPEA4QDxYUExMUFiIYGhgaGCIzICUgICUgMy03LCksNy1RQDg4QFFeT0pPXnFlZXGPiI+7u/sBCgoKCgoKCwwMCw8QDhAPFhQTExQWIhgaGBoYIjMgJSAgJSAzLTcsKSw3LVFAODhAUV5PSk9ecWVlcY+Ij7u7+//CABEIAAIACAMBIgACEQEDEQH/xAAoAAEBAAAAAAAAAAAAAAAAAAAABgEBAQAAAAAAAAAAAAAAAAAAAgT/2gAMAwEAAhADEAAAAJgXj//EABoQAAICAwAAAAAAAAAAAAAAAAIRAAEEBRL/2gAIAQEAAT8A2ZmF43JXTbU//8QAGBEAAgMAAAAAAAAAAAAAAAAAAAIDM4L/2gAIAQIBAT8Ansyp/8QAGBEAAgMAAAAAAAAAAAAAAAAAAAEDMoL/2gAIAQMBAT8Airpn/9k=",
      blurWidth: 8,
      blurHeight: 2,
    },
    position: {
      top: 230,
      left: 728,
    },
    regionCode: "np-kathmandu-1",
    tagLink: "nepal-vps",
  },
  {
    text: "Moscow",
    continent: "Europe",
    url: "russia-vps",
    value: "32",
    tab: "LightNode",
    countryImg: {
      src: "/_next/static/media/Russia.ed38c84a.png",
      height: 34,
      width: 50,
      blurDataURL:
        "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAgAAAAFBAMAAACKv7BmAAAAD1BMVEX////aKQDS0+O1OmoAAKHOlgQdAAAAAnRSTlP+/qap3hAAAAAZSURBVHjaYwADJSBgcAECBmMgYBAUFBQEAB1RAqncaYQKAAAAAElFTkSuQmCC",
      blurWidth: 8,
      blurHeight: 5,
    },
    countryImgCode: "ru",
    banner: {
      src: "/_next/static/media/Moscow.8d92ef3b.jpg",
      height: 501,
      width: 1920,
      blurDataURL:
        "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAoKCgoKCgsMDAsPEA4QDxYUExMUFiIYGhgaGCIzICUgICUgMy03LCksNy1RQDg4QFFeT0pPXnFlZXGPiI+7u/sBCgoKCgoKCwwMCw8QDhAPFhQTExQWIhgaGBoYIjMgJSAgJSAzLTcsKSw3LVFAODhAUV5PSk9ecWVlcY+Ij7u7+//CABEIAAIACAMBIgACEQEDEQH/xAAnAAEBAAAAAAAAAAAAAAAAAAAAAwEBAAAAAAAAAAAAAAAAAAAABf/aAAwDAQACEAMQAAAAoGyv/8QAGhAAAgIDAAAAAAAAAAAAAAAAAQIAAwQiMv/aAAgBAQABPwC9EGM2o7E//8QAFhEAAwAAAAAAAAAAAAAAAAAAAAIx/9oACAECAQE/AEh//8QAGBEAAgMAAAAAAAAAAAAAAAAAAAECMXH/2gAIAQMBAT8Anaw//9k=",
      blurWidth: 8,
      blurHeight: 2,
    },
    position: {
      top: 153,
      left: 586,
    },
    regionCode: "ru-moscow-1",
    tagLink: "russia-vps",
  },
  {
    text: "Buenos Aires",
    continent: "South America",
    url: "argentina-vps",
    value: "33",
    tab: "LightNode",
    countryImg: {
      src: "/_next/static/media/Argentina.b58d1056.png",
      height: 34,
      width: 50,
      blurDataURL:
        "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAgAAAAFBAMAAACKv7BmAAAAIVBMVEX////327X22rS30+230uuyy+KxyuFjruBireBgq91fq933TabMAAAAIUlEQVR42mOYubxrJoOLabALAwOTAAODi1myC8PM5VUzAVeFBvomCSFJAAAAAElFTkSuQmCC",
      blurWidth: 8,
      blurHeight: 5,
    },
    countryImgCode: "ar",
    banner: {
      src: "/_next/static/media/BuenosAires.9856b334.jpg",
      height: 500,
      width: 1920,
      blurDataURL:
        "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAoKCgoKCgsMDAsPEA4QDxYUExMUFiIYGhgaGCIzICUgICUgMy03LCksNy1RQDg4QFFeT0pPXnFlZXGPiI+7u/sBCgoKCgoKCwwMCw8QDhAPFhQTExQWIhgaGBoYIjMgJSAgJSAzLTcsKSw3LVFAODhAUV5PSk9ecWVlcY+Ij7u7+//CABEIAAIACAMBIgACEQEDEQH/xAAoAAEBAAAAAAAAAAAAAAAAAAAABQEBAQAAAAAAAAAAAAAAAAAAAgT/2gAMAwEAAhADEAAAAJgFP//EABsQAAIDAAMAAAAAAAAAAAAAAAECAwQRABIh/9oACAEBAAE/ALzNDWsmMlCqLnXzOf/EABURAQEAAAAAAAAAAAAAAAAAAAAC/9oACAECAQE/AJf/xAAWEQADAAAAAAAAAAAAAAAAAAAAAkH/2gAIAQMBAT8AeH//2Q==",
      blurWidth: 8,
      blurHeight: 2,
    },
    position: {
      top: 395,
      left: 335,
    },
    regionCode: "ar-buenosaires-1",
    tagLink: "argentina-vps",
  },
  {
    text: "Jakarta",
    continent: "Asia",
    url: "indonesia-vps",
    value: "34",
    tab: "LightNode",
    countryImg: {
      src: "/_next/static/media/Jakarta.6be2ece2.png",
      height: 28,
      width: 40,
      blurDataURL:
        "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAgAAAAGBAMAAAAMK8LIAAAAMFBMVEX+/v7MGyv+/v7MGyv+/v7MGyv79/fPS1H////LAAv89/fPS1L////89/fPS1LLAAondfYYAAAADHRSTlPMzNbW2Njx8fn6/f3z89mdAAAAKElEQVR42mMwNjYOZPj///9Pht27dz9nWLVq1TWGM2fOnGBQUlJyAADkeA6fR3QvTAAAAABJRU5ErkJggg==",
      blurWidth: 8,
      blurHeight: 6,
    },
    countryImgCode: "id",
    banner: {
      src: "/_next/static/media/Indonesia.ad472656.jpg",
      height: 500,
      width: 1920,
      blurDataURL:
        "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAoKCgoKCgsMDAsPEA4QDxYUExMUFiIYGhgaGCIzICUgICUgMy03LCksNy1RQDg4QFFeT0pPXnFlZXGPiI+7u/sBCgoKCgoKCwwMCw8QDhAPFhQTExQWIhgaGBoYIjMgJSAgJSAzLTcsKSw3LVFAODhAUV5PSk9ecWVlcY+Ij7u7+//CABEIAAIACAMBIgACEQEDEQH/xAAoAAEBAAAAAAAAAAAAAAAAAAAABgEBAQAAAAAAAAAAAAAAAAAAAwT/2gAMAwEAAhADEAAAALsXB//EABoQAAEFAQAAAAAAAAAAAAAAAAEAAxEhMfH/2gAIAQEAAT8A0vTfAv/EABYRAAMAAAAAAAAAAAAAAAAAAAADMv/aAAgBAgEBPwBcn//EABcRAAMBAAAAAAAAAAAAAAAAAAABAjL/2gAIAQMBAT8ArTP/2Q==",
      blurWidth: 8,
      blurHeight: 2,
    },
    position: {
      top: 342,
      left: 848,
    },
    regionCode: "id-jakarta-1",
    tagLink: "indonesia-vps",
  },
  {
    text: "Mexico City",
    continent: "North America",
    url: "mexico-vps",
    value: "35",
    tab: "LightNode",
    countryImg: {
      src: "/_next/static/media/Mexico.6641de8a.png",
      height: 306,
      width: 536,
      blurDataURL:
        "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAgAAAAFCAIAAAD38zoCAAAAZklEQVR42mNQyPFjCBKcvXbxfzC4P3vuKQaGc+rGDCAJf4YFm1f//PzhxfOnjxcvPQmRkAdLLNq65vKp/ds2LX+8BCyhZgTWEcg1b8Pyb18/f/7+5eH8hUhGBfHPXrcEaseceRAJAHZUP9ZmrCZyAAAAAElFTkSuQmCC",
      blurWidth: 8,
      blurHeight: 5,
    },
    countryImgCode: "mx",
    banner: {
      src: "/_next/static/media/MexicoCity.cdb8d3f8.jpg",
      height: 500,
      width: 1920,
      blurDataURL:
        "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAoKCgoKCgsMDAsPEA4QDxYUExMUFiIYGhgaGCIzICUgICUgMy03LCksNy1RQDg4QFFeT0pPXnFlZXGPiI+7u/sBCgoKCgoKCwwMCw8QDhAPFhQTExQWIhgaGBoYIjMgJSAgJSAzLTcsKSw3LVFAODhAUV5PSk9ecWVlcY+Ij7u7+//CABEIAAIACAMBIgACEQEDEQH/xAAnAAEBAAAAAAAAAAAAAAAAAAAABgEBAAAAAAAAAAAAAAAAAAAAAv/aAAwDAQACEAMQAAAAqQx//8QAGxAAAgEFAAAAAAAAAAAAAAAAAQMAAgQRElH/2gAIAQEAAT8ALWm4ALKsa9n/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oACAECAQE/AH//xAAVEQEBAAAAAAAAAAAAAAAAAAAAAf/aAAgBAwEBPwCv/9k=",
      blurWidth: 8,
      blurHeight: 2,
    },
    position: {
      top: 264,
      left: 188,
    },
    regionCode: "mx-mexico-1",
    tagLink: "mexico-vps",
  },
  {
    text: "Santiago",
    continent: "South America",
    url: "chile-vps",
    value: "36",
    tab: "LightNode",
    countryImg: {
      src: "/_next/static/media/Chile.74822270.webp",
      height: 357,
      width: 536,
      blurDataURL:
        "data:image/webp;base64,UklGRloAAABXRUJQVlA4IE4AAADwAQCdASoIAAUAAkA4JbACdLoAAwhAW5AAzj+pbKKvaSuqEE+IGQEPquHo7QdXZ2cTHaFpYf/OOLz3++/RZv6PPXf5OTLN/9B3+agAAAA=",
      blurWidth: 8,
      blurHeight: 5,
    },
    countryImgCode: "cl",
    banner: {
      src: "/_next/static/media/Santiago.d30dfd06.jpg",
      height: 500,
      width: 1920,
      blurDataURL:
        "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAoKCgoKCgsMDAsPEA4QDxYUExMUFiIYGhgaGCIzICUgICUgMy03LCksNy1RQDg4QFFeT0pPXnFlZXGPiI+7u/sBCgoKCgoKCwwMCw8QDhAPFhQTExQWIhgaGBoYIjMgJSAgJSAzLTcsKSw3LVFAODhAUV5PSk9ecWVlcY+Ij7u7+//CABEIAAIACAMBIgACEQEDEQH/xAAoAAEBAAAAAAAAAAAAAAAAAAAAAgEBAQAAAAAAAAAAAAAAAAAAAgP/2gAMAwEAAhADEAAAAJFz/8QAHBAAAQMFAAAAAAAAAAAAAAAAAQACAwQFEzNC/9oACAEBAAE/AKyaYW5gyv2Hpf/EABcRAAMBAAAAAAAAAAAAAAAAAAABQXH/2gAIAQIBAT8AV0//xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oACAEDAQE/AH//2Q==",
      blurWidth: 8,
      blurHeight: 2,
    },
    position: {
      top: 413,
      left: 278,
    },
    regionCode: "cl-santiago-1",
    tagLink: "chile-vps",
  },
  {
    text: "Yangon",
    continent: "Asia",
    url: "myanmar-vps",
    value: "37",
    tab: "LightNode",
    countryImg: {
      src: "/_next/static/media/Myanmar.bd1bc18d.png",
      height: 357,
      width: 536,
      blurDataURL:
        "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAgAAAAFCAMAAABPT11nAAAAOVBMVEXu/vvyy8nq1pD/zAD/ywD/ygDbwyDXwiLXwhxhx4PEfUrHcDjHaywAtTkAsx7yLE7wADrwADTqACE14TfhAAAALUlEQVR42gVAhw0AIAir4mbz/7EGRGPOQYSzV+9rH6hd4JqC5bX2hBHpVZ7xARbRAV3bC2PgAAAAAElFTkSuQmCC",
      blurWidth: 8,
      blurHeight: 5,
    },
    countryImgCode: "mm",
    banner: {
      src: "/_next/static/media/Yangon.a1800de1.jpg",
      height: 500,
      width: 1920,
      blurDataURL:
        "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAoKCgoKCgsMDAsPEA4QDxYUExMUFiIYGhgaGCIzICUgICUgMy03LCksNy1RQDg4QFFeT0pPXnFlZXGPiI+7u/sBCgoKCgoKCwwMCw8QDhAPFhQTExQWIhgaGBoYIjMgJSAgJSAzLTcsKSw3LVFAODhAUV5PSk9ecWVlcY+Ij7u7+//CABEIAAIACAMBIgACEQEDEQH/xAAnAAEBAAAAAAAAAAAAAAAAAAAABQEBAAAAAAAAAAAAAAAAAAAABP/aAAwDAQACEAMQAAAAsgjf/8QAGRAAAwEBAQAAAAAAAAAAAAAAAQIRBAAD/9oACAEBAAE/ANjuhxFGK31Fhnf/xAAWEQADAAAAAAAAAAAAAAAAAAAAAjH/2gAIAQIBAT8Aan//xAAWEQADAAAAAAAAAAAAAAAAAAAAAjH/2gAIAQMBAT8ASH//2Q==",
      blurWidth: 8,
      blurHeight: 2,
    },
    position: {
      top: 260,
      left: 770,
    },
    regionCode: "mm-yangon-1",
    tagLink: "myanmar-vps",
  },
  {
    text: "Baghdad",
    continent: "Asia",
    url: "iraq-vps",
    value: "38",
    tab: "LightNode",
    countryImg: {
      src: "/_next/static/media/Iraq.77343186.png",
      height: 28,
      width: 40,
      blurDataURL:
        "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAgAAAAGCAYAAAD+Bd/7AAAAlElEQVR42n3KPQrCQBRF4fMyEyRqgqIQtBML0UJw/2twBaayMSoEIZiYv3kOLsALH9ziyJlUQVA6r0Swvx+wBBzWnHa9qsOMJ4RxjOt7xBiaPEesQVxV9SIBVVNzez2IwhF1+2G72qBuwL5VCUTJijvPsiCJpqgqa2/w5Lg/dIMv00XKPJnRti0SCJdrRmhDBFD+7AukaEBRZTHAXgAAAABJRU5ErkJggg==",
      blurWidth: 8,
      blurHeight: 6,
    },
    banner: {
      src: "/_next/static/media/Baghdad.3bff6839.jpg",
      height: 500,
      width: 1920,
      blurDataURL:
        "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAoKCgoKCgsMDAsPEA4QDxYUExMUFiIYGhgaGCIzICUgICUgMy03LCksNy1RQDg4QFFeT0pPXnFlZXGPiI+7u/sBCgoKCgoKCwwMCw8QDhAPFhQTExQWIhgaGBoYIjMgJSAgJSAzLTcsKSw3LVFAODhAUV5PSk9ecWVlcY+Ij7u7+//CABEIAAIACAMBIgACEQEDEQH/xAAoAAEBAAAAAAAAAAAAAAAAAAAABAEBAQAAAAAAAAAAAAAAAAAAAwT/2gAMAwEAAhADEAAAALQkf//EAB0QAAECBwAAAAAAAAAAAAAAAAEAAgMEERMiMWH/2gAIAQEAAT8AuxDKMq9xwI3xf//EABYRAAMAAAAAAAAAAAAAAAAAAAACMf/aAAgBAgEBPwBYf//EABcRAAMBAAAAAAAAAAAAAAAAAAACQXH/2gAIAQMBAT8AaYf/2Q==",
      blurWidth: 8,
      blurHeight: 2,
    },
    position: {
      top: 214,
      left: 610,
    },
    regionCode: "iq-baghdad-1",
    countryImgCode: "iq",
    tagLink: "iraq-vps",
  },
  {
    text: "Bogota",
    continent: "South America",
    url: "colombia-vps",
    value: "39",
    tab: "LightNode",
    countryImg: {
      src: "/_next/static/media/Colombia.3623cc24.png",
      height: 28,
      width: 40,
      blurDataURL:
        "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAgAAAAGBAMAAAAMK8LIAAAAElBMVEX/zQD+ywT2xBjPERmOEmQWR4Lpq30+AAAAHElEQVR42mMQBAIGMFACAoZQIGBwAQIGY2NjYwArSAP93XJSQQAAAABJRU5ErkJggg==",
      blurWidth: 8,
      blurHeight: 6,
    },
    countryImgCode: "co",
    banner: {
      src: "/_next/static/media/Bogota.3be5b078.jpg",
      height: 500,
      width: 1920,
      blurDataURL:
        "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAoKCgoKCgsMDAsPEA4QDxYUExMUFiIYGhgaGCIzICUgICUgMy03LCksNy1RQDg4QFFeT0pPXnFlZXGPiI+7u/sBCgoKCgoKCwwMCw8QDhAPFhQTExQWIhgaGBoYIjMgJSAgJSAzLTcsKSw3LVFAODhAUV5PSk9ecWVlcY+Ij7u7+//CABEIAAIACAMBIgACEQEDEQH/xAAnAAEBAAAAAAAAAAAAAAAAAAAABgEBAAAAAAAAAAAAAAAAAAAABf/aAAwDAQACEAMQAAAAqQ8P/8QAGxAAAQQDAAAAAAAAAAAAAAAAAgABBCETIoL/2gAIAQEAAT8Al6yCFqHAVdr/xAAYEQACAwAAAAAAAAAAAAAAAAAAAgMxcf/aAAgBAgEBPwCCm0//xAAXEQADAQAAAAAAAAAAAAAAAAAAA0Jx/9oACAEDAQE/AGzh/9k=",
      blurWidth: 8,
      blurHeight: 2,
    },
    position: {
      top: 320,
      left: 256,
    },
    regionCode: "co-bogota-2",
    tagLink: "colombia-vps",
  },
  {
    text: "Doha",
    continent: "Asia",
    value: "40",
    tab: "LightNode",
    banner: {
      src: "/_next/static/media/Doha.38ea538b.jpg",
      height: 500,
      width: 1920,
      blurDataURL:
        "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAoKCgoKCgsMDAsPEA4QDxYUExMUFiIYGhgaGCIzICUgICUgMy03LCksNy1RQDg4QFFeT0pPXnFlZXGPiI+7u/sBCgoKCgoKCwwMCw8QDhAPFhQTExQWIhgaGBoYIjMgJSAgJSAzLTcsKSw3LVFAODhAUV5PSk9ecWVlcY+Ij7u7+//CABEIAAIACAMBIgACEQEDEQH/xAAoAAEBAAAAAAAAAAAAAAAAAAAABgEBAQAAAAAAAAAAAAAAAAAAAwT/2gAMAwEAAhADEAAAAKAPF//EABsQAAIBBQAAAAAAAAAAAAAAAAEDAAQRE1Fy/9oACAEBAAE/AM7zUWLmEdHc/8QAFhEAAwAAAAAAAAAAAAAAAAAAAAIx/9oACAECAQE/AFh//8QAFhEAAwAAAAAAAAAAAAAAAAAAAAMy/9oACAEDAQE/AGUf/9k=",
      blurWidth: 8,
      blurHeight: 2,
    },
    position: {
      top: 240,
      left: 650,
    },
    regionCode: "qa-doha-1",
    countryImgCode: "qa",
  },
  {
    text: "Lima",
    continent: "South America",
    value: "41",
    tab: "LightNode",
    banner: {
      src: "/_next/static/media/Peru.09ac3615.png",
      height: 500,
      width: 1903,
      blurDataURL:
        "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAgAAAACCAIAAADq9gq6AAAAPElEQVR42mPIaNpY3L5+8cKVC5dsW7xo2bJF87esXz1jYhdDUVFxYUFOa1NDQ2NXWXlRYU5weV5IX1M2AK98GbllPihJAAAAAElFTkSuQmCC",
      blurWidth: 8,
      blurHeight: 2,
    },
    position: {
      top: 346,
      left: 256,
    },
    regionCode: "pe-lima-1",
    countryImgCode: "pe",
  },
  {
    text: "Japan",
    continent: "Asia",
    value: "999",
    tab: "VU&DO",
    countryImg: i,
    countryImgCode: "jp",
    position: {
      top: 225,
      left: 894,
    },
  },
];

const urls = nodes
  .filter((node) => !!node.regionCode)
  .map((node) => `https://speed.lightnode.com/icmp/${node.regionCode}/info`);

const main = async () => {
  const ips = await Promise.all(
    urls.map(async (url) => {
      // set fetch timeout 3s
      const originalIp = await fetch(url, { timeout: 3000 }).then((res) =>
        res.text(),
      );
      // use regexp to extract ip
      const ip = originalIp.match(/(\d{1,3}\.){3}\d{1,3}/)[0];
      console.log(`${url} ip:`, ip);
      return ip;
    }),
  );

  console.log(ips);
};

main();
