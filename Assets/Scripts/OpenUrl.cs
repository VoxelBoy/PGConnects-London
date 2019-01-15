using UnityEngine;
using UnityEngine.EventSystems;

public class OpenUrl : MonoBehaviour, IPointerClickHandler
{

	public string url;

	public void OnPointerClick(PointerEventData eventData)
	{
		Application.OpenURL(url);
	}
}
